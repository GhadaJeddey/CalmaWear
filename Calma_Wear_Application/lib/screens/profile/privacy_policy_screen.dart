import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Introduction
                    _buildSection(
                      title: 'Introduction',
                      content:
                          'CalmaWear ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application for autism support and monitoring.',
                    ),

                    // Information We Collect
                    _buildSection(
                      title: '1. Information We Collect',
                      content: '',
                    ),
                    _buildSubsection(
                      subtitle: '1.1 Personal Information',
                      content:
                          'We collect information that you provide directly to us, including:\n• Name and email address\n• Phone number\n• Date of birth\n• Profile pictures\n• Child\'s information (name, age, gender, triggers)',
                    ),
                    _buildSubsection(
                      subtitle: '1.2 Health and Sensor Data',
                      content:
                          'Our app collects sensor data to monitor stress levels:\n• Heart rate variability\n• Skin temperature\n• Movement patterns\n• Stress scores and alerts',
                    ),
                    _buildSubsection(
                      subtitle: '1.3 Usage Data',
                      content:
                          'We automatically collect certain information when you use the app:\n• Device information\n• App usage statistics\n• Chat interactions with AI assistant\n• Community posts and events\n• Planner and to-do items',
                    ),

                    // How We Use Your Information
                    _buildSection(
                      title: '2. How We Use Your Information',
                      content:
                          'We use the collected information to:\n• Provide and maintain our services\n• Monitor your child\'s stress levels and send alerts\n• Personalize your experience\n• Generate AI-powered recommendations\n• Enable community features\n• Improve our app and develop new features\n• Communicate with you about updates and changes',
                    ),

                    // Data Storage and Security
                    _buildSection(
                      title: '3. Data Storage and Security',
                      content:
                          'We implement appropriate security measures to protect your information:\n• Data is stored securely using Firebase and Firestore\n• Images and audio are stored on Cloudinary with secure access\n• We use encryption for data transmission\n• Access to personal data is restricted to authorized personnel only',
                    ),

                    // Data Sharing
                    _buildSection(
                      title: '4. Data Sharing and Disclosure',
                      content:
                          'We do not sell your personal information. We may share your information only in the following circumstances:\n• With your explicit consent\n• To comply with legal obligations\n• To protect the rights and safety of our users\n• With service providers who assist in our operations (Firebase, Cloudinary, Google AI)',
                    ),

                    // Your Rights
                    _buildSection(
                      title: '5. Your Rights',
                      content:
                          'You have the right to:\n• Access your personal data\n• Update or correct your information\n• Delete your account and associated data\n• Opt-out of notifications\n• Export your data\n• Object to certain processing activities',
                    ),

                    // Children's Privacy
                    _buildSection(
                      title: '6. Children\'s Privacy',
                      content:
                          'Our app is designed to help parents monitor their children with autism. We collect information about children only through parental consent and for the sole purpose of providing monitoring and support services.',
                    ),

                    // Third-Party Services
                    _buildSection(
                      title: '7. Third-Party Services',
                      content:
                          'Our app uses the following third-party services:\n• Firebase/Firestore (Google): Authentication and database\n• Cloudinary: Media storage\n• Google Generative AI: AI-powered features\n\nThese services have their own privacy policies governing the use of your information.',
                    ),

                    // Changes to Privacy Policy
                    _buildSection(
                      title: '8. Changes to This Privacy Policy',
                      content:
                          'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
                    ),

                    // Contact Us
                    _buildSection(
                      title: '9. Contact Us',
                      content:
                          'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: support@calmawear.com\nAddress: [Your Address]\n\nWe will respond to your inquiry within 30 days.',
                    ),

                    const SizedBox(height: 40),

                    // Acceptance
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        'By using CalmaWear, you acknowledge that you have read and understood this Privacy Policy and agree to its terms.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 10),
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubsection({required String subtitle, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0066FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
