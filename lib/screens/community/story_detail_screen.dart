// screens/community/story_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community_story.dart';
import '../../providers/community_provider.dart';
import 'package:intl/intl.dart';

class StoryDetailScreen extends StatelessWidget {
  final CommunityStory story;

  const StoryDetailScreen({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final communityProvider = Provider.of<CommunityProvider>(context);
    final currentUserId = communityProvider.currentUserId;
    final hasLiked = story.likedBy.contains(currentUserId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Story',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              story.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0066FF),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 16),

            // Author info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      story.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.authorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(story.createdAt),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Like button
                IconButton(
                  onPressed: () {
                    communityProvider.toggleStoryLike(story.id);
                  },
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.red : Colors.grey[400],
                    size: 26,
                  ),
                ),
                Text(
                  '${story.likes}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Read time
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${story.readTime} min read',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            const Divider(height: 32, thickness: 1),

            // Content
            Text(
              story.content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
