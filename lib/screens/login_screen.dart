import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter email & password")));
      return;
    }
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      FirebaseMessaging.instance.getToken().then((token) {
        if (token != null) FirestoreService.updateFcmToken(token);
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') message = "User not found.";
      if (e.code == 'wrong-password') message = "Incorrect password.";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> handleResetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Password reset email sent to $email.")));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.code == 'user-not-found'
                ? "No user found with this email."
                : "Failed to send reset email")));
      }
    }
  }

  void _showResetPasswordModal() {
    final TextEditingController resetEmailController =
        TextEditingController();
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.border(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Reset Password",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
              const SizedBox(height: 15),
              Text(
                "Enter your college email and we'll send you a secure link.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: resetEmailController,
                style: TextStyle(color: textPrimary),
                keyboardType: TextInputType.emailAddress,
                decoration: AppTheme.glassInputDecoration(
                    context, "College Email",
                    prefixIcon:
                        Icon(Icons.email_outlined, color: primary)),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel",
                          style: TextStyle(color: textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [
                          primary,
                          AppTheme.isDark(context)
                              ? const Color(0xFF0055FF)
                              : const Color(0xFF003BB5)
                        ]),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final email =
                              resetEmailController.text.trim();
                          if (email.isNotEmpty) {
                            Navigator.pop(context);
                            handleResetPassword(email);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        child: const Text("Send Link",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 50)
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Text("Log in to the NITJ Marketplace",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, color: textSecondary)),
                    const SizedBox(height: 50),

                    TextField(
                      controller: emailController,
                      style: TextStyle(color: textPrimary),
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppTheme.glassInputDecoration(
                          context, "Email",
                          prefixIcon: Icon(Icons.person_outline,
                              color: primary)),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: textPrimary),
                      decoration: AppTheme.glassInputDecoration(
                        context,
                        "Password",
                        prefixIcon:
                            Icon(Icons.lock_outline, color: primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textSecondary),
                          onPressed: () => setState(() =>
                              _isPasswordVisible =
                                  !_isPasswordVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showResetPasswordModal,
                        child: Text("Forgot Password?",
                            style: TextStyle(
                                color: textSecondary, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Container(
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
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        child: const Text("LOGIN",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style:
                                TextStyle(color: textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterScreen())),
                          child: Text("Create Account",
                              style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      TextDecoration.underline,
                                  decorationColor: primary,
                                  decorationThickness: 2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
