import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'service_locator.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'package:logger/logger.dart';

class ImageService {
  final ApiService _apiService = serviceLocator<ApiService>();
  final AuthService _authService = serviceLocator<AuthService>();
  final Logger _logger = Logger();
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Higher quality
        maxWidth: 1200,   // Increased width
        maxHeight: 1200,  // Increased height
        requestFullMetadata: true, // Get full metadata to validate image
      );
      
      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final String extension = path.extension(file.path).toLowerCase();
        
        // Validate file extension
        if (extension == '.jpg' || extension == '.jpeg' || 
            extension == '.png' || extension == '.gif' || 
            extension == '.webp') {
          _logger.i('Valid image file selected: ${file.path} with extension $extension');
          return file;
        } else {
          _logger.e('Invalid image file extension: $extension');
          throw Exception('Please select a valid image file (JPG, PNG, GIF, or WebP)');
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error picking image: $e');
      rethrow; // Rethrow to handle in the UI
    }
  }

  // Upload profile image to server
  Future<UserModel?> uploadProfileImage(File imageFile) async {
    try {
      _logger.i('Uploading profile image: ${imageFile.path}');
      
      // Create a new Dio instance for this upload
      final dio = Dio();
      dio.options.baseUrl = ApiConfig.baseUrl;
      
      // Add auth token if available
      final token = await _authService.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      // Determine MIME type based on file extension
      final String fileName = path.basename(imageFile.path);
      final String extension = path.extension(fileName).toLowerCase();
      MediaType mediaType;
      
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          mediaType = MediaType('image', 'jpeg');
          break;
        case '.png':
          mediaType = MediaType('image', 'png');
          break;
        case '.gif':
          mediaType = MediaType('image', 'gif');
          break;
        case '.webp':
          mediaType = MediaType('image', 'webp');
          break;
        default:
          mediaType = MediaType('image', 'jpeg'); // Default to JPEG if unknown
      }
      
      _logger.i('File extension: $extension, MIME type: ${mediaType.mimeType}');
      
      // Create form data with the image file and explicit MIME type
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: mediaType,
        ),
      });
      
      // Log the full URL for debugging
      final uploadUrl = ApiConfig.baseUrl + ApiConfig.endpoints.users.uploadProfileImage;
      _logger.i('Uploading to URL: $uploadUrl');
      
      dynamic response;
      
      // Try the upload with the standard endpoint first
      try {
        response = await dio.post(
          ApiConfig.endpoints.users.uploadProfileImage,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json',
            },
          ),
        );
      } catch (e) {
        // If the standard endpoint fails, try with the profile endpoint
        _logger.i('Standard endpoint failed, trying alternative endpoint: ${e.toString()}');
        
        // Try alternative endpoint structure
        response = await dio.post(
          ApiConfig.endpoints.users.profile,  // Use the profile endpoint instead
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json',
            },
          ),
        );
      }
      
      if (response.data == null) {
        _logger.e('Upload profile image response is null');
        throw Exception('Failed to upload profile image: No response from server');
      }
      
      if (response.data['error'] != null) {
        _logger.e('Upload profile image error: ${response.data['error']}');
        throw Exception(response.data['error']);
      }
      
      // Update current user data with new profile image URL
      final updatedUser = UserModel.fromJson(response.data);
      
      // Update auth state with new user data
      await _authService.updateUserProfile({
        'profileImageUrl': updatedUser.profileImageUrl,
      });
      
      _logger.i('Profile image uploaded successfully: ${updatedUser.profileImageUrl}');
      
      return updatedUser;
    } catch (e) {
      _logger.e('Error uploading profile image: $e');
      rethrow;
    }
  }

  // Show image picker dialog
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF262135),
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  try {
                    final File? image = await pickImage(ImageSource.gallery);
                    if (context.mounted) {
                      Navigator.pop(context, image);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context, null); // Close dialog first
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()))
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  try {
                    final File? image = await pickImage(ImageSource.camera);
                    if (context.mounted) {
                      Navigator.pop(context, image);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context, null); // Close dialog first
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()))
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
