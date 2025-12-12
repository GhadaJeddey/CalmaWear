import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

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
                      'Help & Support',
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
                    // Frequently Asked Questions
                    _buildSectionHeader('Frequently Asked Questions'),
                    const SizedBox(height: 16),

                    _buildFAQItem(
                      question: 'How do I monitor my child\'s stress levels?',
                      answer:
                          'Go to the Home screen to view real-time stress monitoring data. The app displays heart rate, skin temperature, and movement patterns. You can set custom stress thresholds in your profile settings.',
                    ),

                    _buildFAQItem(
                      question: 'How do I add or edit my child\'s triggers?',
                      answer:
                          'Navigate to Profile > Child Profile. Scroll down to the "Triggers" section where you can add common triggers (loud noises, bright lights, etc.) and adjust their intensity levels using the slider.',
                    ),

                    _buildFAQItem(
                      question: 'What are stress alerts and how do they work?',
                      answer:
                          'Stress alerts notify you when your child\'s stress score exceeds your set threshold. You can configure alert frequency and notification preferences in Settings > Notification Settings.',
                    ),

                    _buildFAQItem(
                      question: 'How do I use the planner feature?',
                      answer:
                          'The Planner helps you organize daily tasks and routines. You can create custom to-do items, set reminders, and use default templates. Access it from the bottom navigation bar.',
                    ),

                    _buildFAQItem(
                      question: 'How do I share my story in the community?',
                      answer:
                          'Go to the Community tab, tap "Share Your Story", fill in your story details, and optionally add images. Your story will be visible to other parents in the community.',
                    ),

                    _buildFAQItem(
                      question: 'Can I delete my account and data?',
                      answer:
                          'Yes. Go to Profile > Settings > Delete Account. This will permanently remove your account and all associated data from our servers. This action cannot be undone.',
                    ),

                    _buildFAQItem(
                      question: 'How do I change my password?',
                      answer:
                          'Navigate to Profile > Settings > Password Manager. Enter your current password, then your new password twice to confirm. If you forgot your password, use the "Forgot?" link to receive a reset email.',
                    ),

                    const SizedBox(height: 32),

                    // Getting Started
                    _buildSectionHeader('Getting Started'),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.child_care,
                      title: 'Set Up Child Profile',
                      description:
                          'Complete your child\'s profile with their name, age, gender, and common triggers to get personalized monitoring.',
                    ),

                    _buildInfoCard(
                      icon: Icons.notifications_active,
                      title: 'Configure Alerts',
                      description:
                          'Set your preferred stress threshold and notification settings to receive timely alerts.',
                    ),

                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Join the Community',
                      description:
                          'Connect with other parents, share experiences, and participate in community events.',
                    ),

                    const SizedBox(height: 32),

                    // Contact Support
                    _buildSectionHeader('Contact Support'),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0066FF).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: const Color(0xFF0066FF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Email Support',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'support@calmawear.com',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We typically respond within 24 hours',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App Version
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'CalmaWear',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0066FF),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0066FF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
