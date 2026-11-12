import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';

class ManagePhotosScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String itemId;

  const ManagePhotosScreen(
      {super.key, required this.itemData, required this.itemId});

  @override
  State<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemData['images'] != null)
      _images = List<dynamic>.from(widget.itemData['images']);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 2 images allowed")));
      return;
    }
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) setState(() => _images.add(File(image.path)));
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  Future<void> _savePhotos() async {
    setState(() => _isLoading = true);
    try {
      List<String> finalUrls = [];
      for (var img in _images) {
        if (img is String) {
          finalUrls.add(img);
        } else if (img is File) {
          final url = Uri.parse(
              'https://api.cloudinary.com/v1_1/dwrmzi6ov/image/upload');
          final request = http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = 'dormdeal_preset'
            ..files.add(
                await http.MultipartFile.fromPath('file', img.path));
          final response = await request.send();
          if (response.statusCode == 200) {
            final responseData = await response.stream.toBytes();
            final jsonMap =
                jsonDecode(String.fromCharCodes(responseData));
            finalUrls.add(jsonMap['secure_url']);
          } else {
            throw Exception(
                "Cloudinary upload failed: ${response.statusCode}");
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({'images': finalUrls});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Photos Updated Successfully!"),
            backgroundColor: AppTheme.primary(context)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPicker() {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: primary),
              title: Text('Camera', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.image, color: primary),
              title: Text('Gallery', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(dynamic img, int index) {
    final primary = AppTheme.primary(context);
    return Container(
      key: ValueKey(img.hashCode),
      width: 140,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: index == 0 ? primary : AppTheme.border(context, opacity: 0.2),
          width: index == 0 ? 2 : 1,
        ),
        boxShadow: index == 0
            ? [
                BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: img is String
                ? Image.network(img, fit: BoxFit.cover)
                : Image.file(img as File, fit: BoxFit.cover),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text("MAIN THUMBNAIL",
                      style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          Positioned(
            top: -5,
            right: -5,
            child: IconButton(
              icon: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.redAccent),
                padding: const EdgeInsets.all(4),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 16),
              ),
              onPressed: () => _removeImage(index),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Edit Photos: ${widget.itemData['name'] ?? 'Item'}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Drag and drop to reorder",
                style: TextStyle(
                    color: primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            SizedBox(
              height: 180,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: _reorder,
                proxyDecorator: (child, index, animation) =>
                    AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Material(
                      color: Colors.transparent, child: child),
                  child: child,
                ),
                children: [
                  for (int i = 0; i < _images.length; i++)
                    _buildImageTile(_images[i], i),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_images.length < 2)
              InkWell(
                onTap: _showPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgOpaque(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: primary.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: primary.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withOpacity(0.1)),
                        child: Icon(Icons.add, size: 40, color: primary),
                      ),
                      const SizedBox(height: 10),
                      Text("ADD PHOTO (${_images.length}/2)",
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            SafeArea(
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    primary,
                    isDark
                        ? const Color(0xFF0055FF)
                        : const Color(0xFF003BB5)
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2)
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _savePhotos,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text("SAVE PHOTOS",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
