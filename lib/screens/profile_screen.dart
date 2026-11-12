import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'wishlist_screen.dart';
import 'help_support_screen.dart';
import 'admin_dashboard_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDeleting = false;

  Widget _buildGlassCard({required Widget child, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.6)
        : Colors.white.withOpacity(0.9);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    bool isPasswordVisible = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        title: Text("Delete Account?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This will permanently delete your profile, all your posted items, and chat history. This action cannot be undone.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Enter password to confirm",
                hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white54 : Colors.black54),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE EVERYTHING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      );
      },
      ),
    );

    if (confirmed == true) {
      final password = passwordController.text.trim();
      if (password.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password is required")));
        return;
      }

      setState(() => _isDeleting = true);

      try {
        // 1. Re-authenticate
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);

        final uid = user.uid;
        final db = FirebaseFirestore.instance;

        // 2. Cascade Delete
        // A. Delete Items
        final items = await db.collection('items').where('userId', isEqualTo: uid).get();
        for (var doc in items.docs) {
          await doc.reference.delete();
        }

        // B. Delete Chats & Messages
        final chats = await db.collection('chats').where('participants', arrayContains: uid).get();
        for (var chatDoc in chats.docs) {
          final messages = await chatDoc.reference.collection('messages').get();
          for (var msg in messages.docs) {
            await msg.reference.delete();
          }
          await chatDoc.reference.delete();
        }

        // C. Delete User Document
        await db.collection('users').doc(uid).delete();

        // D. Delete Auth User
        await user.delete();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          String errorMessage = "An error occurred. Please try again.";
          if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
            errorMessage = "Invalid password";
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    bool isOldPassVisible = false;
    bool isNewPassVisible = false;
    bool isConfirmPassVisible = false;

    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final primaryColor = Theme.of(context).colorScheme.primary;
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryColor, width: 1),
          ),
        title: Text("Change Password", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                obscureText: !isOldPassVisible,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Current Password",
                  hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                  suffixIcon: IconButton(
                    icon: Icon(isOldPassVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () {
                      setState(() {
                        isOldPassVisible = !isOldPassVisible;
                      });
                    },
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassController,
                obscureText: !isNewPassVisible,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "New Password",
                  hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                  suffixIcon: IconButton(
                    icon: Icon(isNewPassVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () {
                      setState(() {
                        isNewPassVisible = !isNewPassVisible;
                      });
                    },
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassController,
                obscureText: !isConfirmPassVisible,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Confirm New Password",
                  hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPassVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () {
                      setState(() {
                        isConfirmPassVisible = !isConfirmPassVisible;
                      });
                    },
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              String oldPass = oldPassController.text.trim();
              String newPass = newPassController.text.trim();
              String confirmPass = confirmPassController.text.trim();

              if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
                return;
              }
              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                return;
              }
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
                return;
              }

              try {
                // Re-authenticate user
                AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPass);
                await user.reauthenticateWithCredential(credential);
                
                // Update password
                await user.updatePassword(newPass);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  String errorMessage = "An error occurred. Please try again.";
                  if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
                    errorMessage = "Invalid current password";
                  } else if (e.message != null) {
                    errorMessage = e.message!;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                }
              }
            },
            child: Text("UPDATE", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      );
      },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return Stack(
      children: [
        Scaffold(
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              final primaryColor = Theme.of(context).colorScheme.primary;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryColor));
              }

              String name = "";
              String email = "";
              String? profileImageUrl;
              bool notificationsEnabled = true;

              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String fetchedName = userData['name']?.toString() ?? "";
                String fetchedEmail = userData['email']?.toString() ?? "";
                name = fetchedName.isNotEmpty ? fetchedName : (user.displayName ?? "");
                email = fetchedEmail.isNotEmpty ? fetchedEmail : (user.email ?? "");
                profileImageUrl = userData['profileImageUrl']?.toString();
                notificationsEnabled = userData['notificationsEnabled'] ?? true;
              } else {
                name = user.displayName ?? "";
                email = user.email ?? "";
              }

              return Container(
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Profile Card
                      _buildGlassCard(
                        context: context,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: profileImageUrl == null || profileImageUrl.isEmpty
                                      ? Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.primary)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : 'User',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email.isNotEmpty ? email : 'No email provided',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(currentName: name, currentEmail: email)));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Activity
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.primary),
                              title: Text('Wishlist', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              subtitle: Text('Items you have saved', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Unified Settings & Account
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          children: [
                            if (email.trim().toLowerCase() == 'test@nitj.ac.in') ...[
                              ListTile(
                                leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                                title: const Text('Owner Dashboard', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Verify Pending Goods', style: TextStyle(color: Colors.amber, fontSize: 11)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                                },
                              ),
                              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ],
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (context, currentMode, child) {
                                return ListTile(
                                  leading: Icon(Icons.brightness_6, color: Theme.of(context).colorScheme.primary),
                                  title: Text('Light Mode', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                  trailing: Switch(
                                    value: currentMode == ThemeMode.light,
                                    activeColor: Theme.of(context).colorScheme.primary,
                                    onChanged: (bool value) {
                                      themeNotifier.value = value ? ThemeMode.light : ThemeMode.dark;
                                    },
                                  ),
                                );
                              },
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.primary),
                              title: Text('Notifications', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              trailing: Switch(
                                value: notificationsEnabled,
                                activeColor: Theme.of(context).colorScheme.primary,
                                onChanged: (bool value) async {
                                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                    'notificationsEnabled': value,
                                  }, SetOptions(merge: true));
                                },
                              ),
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                              title: Text('Change Password', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                              onTap: _handleChangePassword,
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                              title: Text('Privacy Policy', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                              },
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                              title: Text('Help & Support', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                              },
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: Icon(Icons.logout, color: Theme.of(context).textTheme.bodySmall?.color),
                              title: Text('Logout', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
                                    final textColor = isDark ? Colors.white : Colors.black87;
                                    final primaryColor = Theme.of(context).colorScheme.primary;
                                    return AlertDialog(
                                      backgroundColor: bgColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(color: primaryColor, width: 1),
                                      ),
                                      title: Text("Logout?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                      content: Text("Are you sure you want to leave? You'll need to login again to access your items and chats.", 
                                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                                        ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  );
                                },
                              );

                                if (confirmed == true) {
                                  await FirebaseAuth.instance.signOut();
                                  if (!context.mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ListTile(
                              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                              title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              subtitle: Text('Permanently remove all your data', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 11)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                              onTap: _handleDeleteAccount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isDeleting)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.redAccent),
                    const SizedBox(height: 20),
                    Text(
                      "Wiping all data...",
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This may take a few moments",
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}