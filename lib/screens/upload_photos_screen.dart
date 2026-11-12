// ─── upload_photos_screen.dart ───────────────────────────────────────────────
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';

class UploadPhotosScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const UploadPhotosScreen({super.key, required this.itemData});

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 2 images allowed")));
      return;
    }
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) setState(() => _selectedImages.add(File(image.path)));
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<void> _postItem() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      final userId =
          FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      for (final imageFile in _selectedImages) {
        if (!await imageFile.exists())
          throw Exception("Image file not found");
        final url = Uri.parse(
            'https://api.cloudinary.com/v1_1/dwrmzi6ov/image/upload');
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = 'dormdeal_preset'
          ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path));
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.toBytes();
          final jsonMap = jsonDecode(String.fromCharCodes(responseData));
          imageUrls.add(jsonMap['secure_url']);
        } else {
          throw Exception("Cloudinary upload failed: ${response.statusCode}");
        }
      }

      final String name = widget.itemData['name'];
      final String lowerName = name.toLowerCase();
      final List<String> searchKeywords = lowerName
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList()
        ..add(lowerName.replaceAll(RegExp(r'\s+'), ''))
        ..add(lowerName);

      widget.itemData['searchKeywords'] = searchKeywords.toSet().toList();
      widget.itemData['userId'] = userId;
      widget.itemData['createdAt'] = FieldValue.serverTimestamp();
      widget.itemData['images'] = imageUrls;
      widget.itemData['status'] = 'pending';

      await FirebaseFirestore.instance
          .collection('items')
          .add(widget.itemData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item posted successfully!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to post: $e")));
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

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final isDark = AppTheme.isDark(context);
    final canPost = _selectedImages.isNotEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Upload Photos"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(width: 8),
                Expanded(
                    child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: primary.withOpacity(0.8),
                                  blurRadius: 8)
                            ]))),
              ],
            ),
            const SizedBox(height: 10),
            Text("Step 2: Upload Photos",
                style: TextStyle(
                    color: primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            InkWell(
              onTap: _showPicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 150,
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
                    Text("TAP TO ADD IMAGE",
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withOpacity(0.5)),
              ),
              child: Text("Max 2 High-Res Slots",
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) => Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.border(context, opacity: 0.2)),
                        image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: IconButton(
                        icon: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                        onPressed: () => _removeImage(index),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: canPost
                          ? [
                              primary,
                              isDark
                                  ? const Color(0xFF0055FF)
                                  : const Color(0xFF003BB5)
                            ]
                          : [AppTheme.cardBg(context), AppTheme.cardBg(context)],
                    ),
                    boxShadow: canPost
                        ? [
                            BoxShadow(
                                color: primary.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: canPost ? (_isLoading ? null : _postItem) : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("POST ITEM",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
