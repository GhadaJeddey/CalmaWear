// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/keys.dart';

class CloudinaryService {
  // === CONFIGURATION ===
  // Using secure configuration from ApiKeys
  static String get _cloudName => ApiKeys.cloudinaryCloudName;
  static String get _apiKey => ApiKeys.cloudinaryApiKey;
  static String get _apiSecret => ApiKeys.cloudinaryApiSecret;

  // URLs Cloudinary
  static String get _imageUploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Singleton pattern
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // === GENERATE SIGNATURE FOR SIGNED UPLOAD ===
  String _generateSignature(Map<String, String> params) {
    // Sort parameters alphabetically and create string to sign
    final sortedKeys = params.keys.toList()..sort();
    final stringToSign = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Append API secret and generate SHA-1 hash
    final dataToSign = '$stringToSign$_apiSecret';
    final bytes = utf8.encode(dataToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  // === UPLOAD IMAGE PROFIL PARENT (accepts XFile for web compatibility) ===
  Future<String?> uploadParentProfileImage(
    XFile imageFile,
    String userId,
  ) async {
    return await _uploadImageFromXFile(
      imageFile,
      folder: 'calma_wear/profiles/parents',
      publicId: 'parent_$userId',
    );
  }

  // === UPLOAD IMAGE PROFIL ENFANT ===
  Future<String?> uploadChildProfileImage(
    XFile imageFile,
    String userId,
  ) async {
    return await _uploadImageFromXFile(
      imageFile,
      folder: 'calma_wear/profiles/children',
      publicId: 'child_$userId',
    );
  }

  // === UPLOAD IMAGE ÉVÉNEMENT COMMUNAUTÉ ===
  Future<String?> uploadEventImage(XFile imageFile, {String? eventId}) async {
    final id = eventId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return await _uploadImageFromXFile(
      imageFile,
      folder: 'calma_wear/events',
      publicId: 'event_$id',
    );
  }

  // === UPLOAD IMAGE STORY COMMUNAUTÉ ===
  Future<String?> uploadStoryImage(XFile imageFile, {String? storyId}) async {
    final id = storyId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return await _uploadImageFromXFile(
      imageFile,
      folder: 'calma_wear/stories',
      publicId: 'story_$id',
    );
  }

  // === UPLOAD IMAGE FROM XFILE (Web compatible) ===
  Future<String?> _uploadImageFromXFile(
    XFile imageFile, {
    required String folder,
    String? publicId,
  }) async {
    try {
      print('📸 Starting image upload to Cloudinary...');

      // Read bytes from XFile (works on both Web and Mobile)
      final Uint8List bytes = await imageFile.readAsBytes();
      final String fileName = imageFile.name;

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // Generate signature
      final params = <String, String>{'folder': folder, 'timestamp': timestamp};
      if (publicId != null) {
        params['public_id'] = publicId;
        params['overwrite'] = 'true';
      }
      final signature = _generateSignature(params);

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_imageUploadUrl));

      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      if (publicId != null) {
        request.fields['public_id'] = publicId;
        request.fields['overwrite'] = 'true';
      }

      // Determine content type from filename
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      // Add file from bytes (works on Web)
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);

        final imageUrl = jsonResponse['secure_url'];
        print('✅ Image uploaded: $imageUrl');
        print('📊 Size: ${jsonResponse['bytes']} bytes');
        print(
          '📐 Dimensions: ${jsonResponse['width']}x${jsonResponse['height']}',
        );

        return imageUrl;
      } else {
        final errorData = await response.stream.bytesToString();
        print('❌ Upload error: ${response.statusCode}');
        print('Details: $errorData');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Upload exception: $e');
      print('Stack: $stackTrace');
      return null;
    }
  }

  // === UPLOAD FROM BYTES DIRECTLY ===
  Future<String?> uploadFromBytes(
    Uint8List bytes,
    String fileName, {
    required String folder,
    String? publicId,
  }) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // Generate signature
      final params = <String, String>{'folder': folder, 'timestamp': timestamp};
      if (publicId != null) {
        params['public_id'] = publicId;
        params['overwrite'] = 'true';
      }
      final signature = _generateSignature(params);

      var request = http.MultipartRequest('POST', Uri.parse(_imageUploadUrl));

      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      if (publicId != null) {
        request.fields['public_id'] = publicId;
        request.fields['overwrite'] = 'true';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      print('❌ Upload exception: $e');
      return null;
    }
  }

  // === TRANSFORMATIONS D'IMAGE (optimisation via URL) ===
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String fit = 'fill',
  }) {
    try {
      if (!originalUrl.contains('cloudinary')) return originalUrl;

      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return originalUrl;

      final List<String> transforms = ['q_auto', 'f_auto'];
      if (width != null) transforms.add('w_$width');
      if (height != null) transforms.add('h_$height');
      transforms.add('c_$fit');

      final transformation = transforms.join(',');
      pathSegments.insert(uploadIndex + 1, transformation);

      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        pathSegments: pathSegments,
      ).toString();
    } catch (e) {
      return originalUrl;
    }
  }

  // === GET THUMBNAIL URL ===
  static String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedUrl(
      originalUrl,
      width: size,
      height: size,
      fit: 'thumb',
    );
  }

  // === GET PROFILE IMAGE URL (optimized) ===
  static String getProfileImageUrl(String originalUrl) {
    return getOptimizedUrl(originalUrl, width: 200, height: 200, fit: 'fill');
  }
}
