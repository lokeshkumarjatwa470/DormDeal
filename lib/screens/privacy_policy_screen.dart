import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection(String title, String body, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: bodyColor,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? const Color(0xFF1E1E1E).withOpacity(0.4) : Colors.white.withOpacity(0.9);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.2);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text('Policies', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Privacy & Security",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            shadows: [
                              Shadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildSection(
                          "1. Information We Collect",
                          "We collect your name, @nitj.ac.in email address, profile image, and item listings (including descriptions, prices, and optional contact info) when you register and use the app. We also securely collect chat messages sent between buyers and sellers.",
                          context,
                        ),
                        _buildSection(
                          "2. How We Use Your Data",
                          "Your data is used to provide a secure marketplace strictly for the NITJ community. We use your email for authentication, your profile info to identify you to peers, and chat data to deliver real-time messages and push notifications.",
                          context,
                        ),
                        _buildSection(
                          "3. Data Sharing & Visibility",
                          "We do not sell or rent your personal data. Your account is strictly secured by Google Firebase infrastructure. However, any information you explicitly post in item listings will be visible to other registered students.",
                          context,
                        ),
                        _buildSection(
                          "4. In-App Communications",
                          "All in-app chats are stored securely to facilitate dealing. For community safety, you can block other users at any time. We recommend sharing sensitive details like dorm locations only when comfortable.",
                          context,
                        ),
                        _buildSection(
                          "5. Data Retention & Deletion",
                          "Your data is retained as long as your account remains active. You can permanently delete your account, listings, and full chat history at any time directly from the Profile settings.",
                          context,
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Effective Date: March 2026",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
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
                    side: BorderSide(color: primaryColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: primaryColor.withOpacity(0.3),
                    elevation: 10,
                  ),
                  child: Text(
                    "I AGREE",
                    style: TextStyle(
                      color: primaryColor,
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
