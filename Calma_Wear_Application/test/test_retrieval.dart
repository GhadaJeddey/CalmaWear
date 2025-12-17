import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔥 QUICK FIRESTORE TEST\n');

  // ====== PUT YOUR VALUES HERE ======
  String projectId =
      'your-project-id'; // From Firebase Console > Project Settings
  String apiKey =
      'your-web-api-key'; // From Firebase Console > Project Settings > General
  String userId = 'your-user-id'; // From Firebase Auth (check your app logs)
  // ==================================

  // Test the connection
  await testFirestore(projectId, apiKey, userId);
}

Future<void> testFirestore(
  String projectId,
  String apiKey,
  String userId,
) async {
  print('Testing: users/$userId/daily_stats');
  print('=' * 50);

  try {
    // Build the Firestore REST API URL
    String url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$userId/daily_stats?key=$apiKey';

    // Make HTTP request
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();

    // Read response
    String body = await response.transform(utf8.decoder).join();

    print('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(body);
      List<dynamic> documents = data['documents'] ?? [];

      print('\n✅ SUCCESS! Found ${documents.length} documents\n');

      if (documents.isEmpty) {
        print('⚠️  NO DATA FOUND!');
        print('The collection exists but is empty.');
        print('\nPossible issues:');
        print('1. Data is not being written to Firestore');
        print('2. Wrong user ID: $userId');
        print('3. Check Firestore Console: console.firebase.google.com');
      } else {
        // Show first 3 documents
        for (int i = 0; i < documents.length && i < 3; i++) {
          var doc = documents[i];
          String name = doc['name'];
          Map<String, dynamic> fields = doc['fields'] ?? {};

          // Get document ID (date)
          List<String> parts = name.split('/');
          String docId = parts.last;

          print('📄 Document $i: $docId');
          print(
            '   maxHeartRate: ${fields['maxHeartRate']?['doubleValue'] ?? 'N/A'}',
          );
          print(
            '   avgBreathingRate: ${fields['avgBreathingRate']?['doubleValue'] ?? 'N/A'}',
          );
          print('   maxNoise: ${fields['maxNoise']?['doubleValue'] ?? 'N/A'}');
          print(
            '   maxMovement: ${fields['maxMovement']?['doubleValue'] ?? 'N/A'}',
          );
          print('');
        }

        if (documents.length > 3) {
          print('... and ${documents.length - 3} more documents');
        }
      }
    } else if (response.statusCode == 404) {
      print('\n❌ COLLECTION NOT FOUND!');
      print('Check:');
      print('1. Project ID: $projectId');
      print('2. User document exists: users/$userId');
      print('3. Collection name: daily_stats (not dailyStats)');
    } else if (response.statusCode == 403) {
      print('\n❌ PERMISSION DENIED!');
      print('Check Firestore security rules at:');
      print(
        'https://console.firebase.google.com/project/$projectId/firestore/rules',
      );
    } else {
      print('\n❌ ERROR: $body');
    }
  } catch (e) {
    print('\n❌ EXCEPTION: $e');
    if (e is SocketException) {
      print('Check internet connection');
    }
  }

  print('\n' + '=' * 50);
  print('Test complete.');
}
