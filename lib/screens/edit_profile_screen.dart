import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedAvatarUrl;
  bool _isLoading = true;

  final List<String> _avatars = [
    'https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-glasses_23-2149436191.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-bald-person_23-2149436183.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-long-hair_23-2149436197.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-pink-hair_23-2149436186.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-beard_23-2149436185.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-blonde-hair_23-2149436180.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-brown-hair_23-2149436182.jpg',
    'https://img.freepik.com/free-psd/3d-render-avatar-character_23-2150611762.jpg',
    'https://img.freepik.com/free-psd/3d-render-avatar-character_23-2150611765.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-rainbow-sunglasses_23-2149436196.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person-with-rainbow-sunglasses_23-2149436195.jpg',
    'https://img.freepik.com/free-psd/3d-illustration-person_23-2149436179.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _emailController.text = widget.currentEmail;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text =
                data['name'] ?? user.displayName ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _dobController.text = data['dob'] ?? '';
            _selectedAvatarUrl = data['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      } catch (_) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showAvatarPicker() {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: primary.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose an Avatar',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarUrl = avatar);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAvatarUrl == avatar
                              ? primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                          backgroundImage: NetworkImage(avatar)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'profileImageUrl': _selectedAvatarUrl,
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    final textPrimary = AppTheme.textPrimary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textPrimary.withOpacity(0.7))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textPrimary),
          decoration: AppTheme.glassInputDecoration(context, hint,
              hintText: hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text('EDIT PROFILE',
            style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: primary, size: 28),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: primary.withOpacity(0.5),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: primary.withOpacity(0.15),
                                    blurRadius: 20,
                                    spreadRadius: 5)
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.cardBg(context),
                              backgroundImage: _selectedAvatarUrl != null
                                  ? NetworkImage(_selectedAvatarUrl!)
                                  : null,
                              child: _selectedAvatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 50, color: primary)
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarPicker,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: scaffoldBg, width: 3),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt,
                                  color: primary, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField('Name', 'Enter your name', _nameController),
                  const SizedBox(height: 16),

                  // Read-only email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: textPrimary.withOpacity(0.7))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
                        style: TextStyle(color: textSecondary),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                              color: AppTheme.textHint(context)),
                          filled: true,
                          fillColor: AppTheme.isDark(context)
                              ? const Color(0xFF1E1E1E).withOpacity(0.4)
                              : Colors.grey.withOpacity(0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                              onPressed: () {},
                              child: Text('Verify',
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField('Phone Number', 'Enter your phone number',
                      _phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),

                  _buildTextField(
                      'Date of birth', 'DD/MM/YYYY', _dobController,
                      keyboardType: TextInputType.datetime),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
