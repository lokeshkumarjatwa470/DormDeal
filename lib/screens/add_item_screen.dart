import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import 'upload_photos_screen.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? editItemId;

  const AddItemScreen({super.key, this.initialData, this.editItemId});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final yearController = TextEditingController();
  final emailController = TextEditingController();

  String? _selectedLocation;
  final List<String> _hostels = [
    'BH1','BH2','BH3','BH4','BH5','BH6','BH7','MBH','GH1','GH2','MGH',
  ];

  String? _selectedCategory;
  final List<String> _categories = [
    'Books','Electronics','Furniture','Hostel Essentials',
    'Sports','Fashion','Stationery','Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      descController.text = widget.initialData!['description'] ?? '';
      priceController.text = widget.initialData!['price']?.toString() ?? '';
      yearController.text = widget.initialData!['year'] ?? '';
      emailController.text = widget.initialData!['email'] ?? '';
      final loc = widget.initialData!['location'] ?? '';
      if (_hostels.contains(loc)) _selectedLocation = loc;
      final cat = widget.initialData!['category'] ?? '';
      for (String c in _categories) {
        if (c.toLowerCase() == cat.toLowerCase()) {
          _selectedCategory = c;
          break;
        }
      }
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) emailController.text = user!.email!;
    }
  }

  void goToNextScreen() async {
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        priceController.text.isEmpty ||
        yearController.text.isEmpty ||
        emailController.text.isEmpty ||
        _selectedLocation == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")));
      return;
    }

    final double priceValue =
        double.tryParse(priceController.text.trim()) ?? 0.0;
        
    if (priceValue < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Price amount entered must be greater than or equal to ₹50")));
      return;
    }

    final Map<String, dynamic> itemData = {
      'name': nameController.text.trim(),
      'description': descController.text.trim(),
      'price': priceController.text.trim(),
      'price_value': priceValue,
      'year': yearController.text.trim(),
      'email': emailController.text.trim(),
      'location': _selectedLocation!,
      'category': _selectedCategory!.toLowerCase(),
    };

    if (widget.editItemId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.editItemId)
            .update(itemData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Details Updated Successfully!'),
            backgroundColor: AppTheme.primary(context),
          ));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: $e')));
        }
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                UploadPhotosScreen(itemData: itemData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);

    InputDecoration fieldDec(String label) =>
        AppTheme.glassInputDecoration(context, label);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Sell Item"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                children: [
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border(context, opacity: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.editItemId != null
                    ? "Edit Item Details"
                    : "Step 1: Item Details",
                style: TextStyle(
                    color: primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                  controller: nameController,
                  style: TextStyle(color: textPrimary),
                  decoration: fieldDec("Item Title")),
              const SizedBox(height: 15),
              TextField(
                  controller: descController,
                  style: TextStyle(color: textPrimary),
                  decoration: fieldDec("Description")),
              const SizedBox(height: 15),
              TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimary),
                  decoration: fieldDec("Price")),
              const SizedBox(height: 15),
              TextField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimary),
                  decoration: fieldDec("Year of Purchase")),
              const SizedBox(height: 15),
              TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textPrimary),
                  decoration: fieldDec("Email")),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedLocation,
                dropdownColor: AppTheme.cardBg(context),
                style: TextStyle(color: textPrimary),
                decoration: fieldDec("Location (Hostel)"),
                items: _hostels
                    .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(h,
                            style: TextStyle(color: textPrimary))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedLocation = v),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppTheme.cardBg(context),
                style: TextStyle(color: textPrimary),
                decoration: fieldDec("Category"),
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: TextStyle(color: textPrimary))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 40),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: AppTheme.isDark(context)
                            ? [
                                const Color(0xFF00E5FF),
                                const Color(0xFF0055FF)
                              ]
                            : [
                                const Color(0xFF0055FF),
                                const Color(0xFF003BB5)
                              ],
                      ),
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
                      onPressed: goToNextScreen,
                      child: Text(
                        widget.editItemId != null
                            ? "SAVE CHANGES"
                            : "NEXT",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
