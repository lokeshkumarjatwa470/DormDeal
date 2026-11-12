import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _buildFAQ(BuildContext context, String question, String answer) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.help_outline, color: primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            answer,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.4)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "How can we help?",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: primary,
                            shadows: isDark
                                ? [Shadow(color: primary, blurRadius: 10)]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildFAQ(
                          context,
                          "How do I sell an item?",
                          "Tap the 'Sell' tab on the home screen, fill in the details like name, description, price, and upload photos. Then press 'Post Item'.",
                        ),

                        _buildFAQ(
                          context,
                          "How do I buy an item?",
                          "Browse the marketplace, tap on an item you like, and use the 'Make Offer' or 'In-App Chat' feature to negotiate the price directly with the seller.",
                        ),

                        _buildFAQ(
                          context,
                          "Why do I need a college email?",
                          "To ensure a safe and exclusive marketplace for our community, we require a valid @nitj.ac.in email address to register.",
                        ),

                        _buildFAQ(
                          context,
                          "How do I change my password?",
                          "You can securely change your password by navigating to the Profile screen and selecting 'Change Password'.",
                        ),

                        _buildFAQ(
                          context,
                          "How do I delete my account?",
                          "If you wish to permanently erase your profile, items, and chat history, go to your Profile and tap on 'Delete Account'.",
                        ),

                        _buildFAQ(
                          context,
                          "Is my data secure?",
                          "Yes, we strictly collect your @nitj.ac.in email and basic details. All chats and profile data are securely handled. You can review our Privacy Policy in the Profile section for more info.",
                        ),

                        _buildFAQ(
                          context,
                          "Can I report a suspicious user?",
                          "If you encounter a suspicious user or unfair activity, you can block them directly from the chat screen to restrict all interactions.",
                        ),

                        Divider(
                          color: isDark ? Colors.white24 : Colors.black12,
                          height: 40,
                        ),

                        Text(
                          "Contact Support",
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Still need help? Reach out to the campus administration or our dedicated student support team at:",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: primary),
                              const SizedBox(width: 10),
                              Text(
                                "support@nitj.ac.in",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: primary.withOpacity(0.3),
                    elevation: 10,
                  ),
                  child: Text(
                    "DONE",
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
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
