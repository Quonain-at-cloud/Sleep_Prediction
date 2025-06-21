import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter/services.dart';
import '../services/service_locator.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await serviceLocator.auth.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickAndUploadImage() async {
    try {
      // Show image picker dialog
      final imageFile = await serviceLocator.image.showImagePickerDialog(context);
      
      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
          _isUploading = true;
        });
        
        // Upload image to server
        final updatedUser = await serviceLocator.image.uploadProfileImage(imageFile);
        
        setState(() {
          _currentUser = updatedUser;
          _isUploading = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}'))
      );
    }
  }
  
  // Get profile image
  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(_currentUser!.profileImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF262135),
      endDrawer: const CustomProfileDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile picture with edit button
            Stack(
              children: [
                // Profile picture
                Container(
                  height: 160, // Diameter = 2 * radius
                  width: 160,  // Diameter = 2 * radius
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFC9E9), // Pink
                        Color(0xFFF5F2B8), // Yellow
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Border thickness
                    child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2D2041),
                            strokeWidth: 3.0, // Thicker loading indicator
                          ),
                        )
                      : CircleAvatar(
                          radius: 75, // Larger inner radius
                          backgroundColor: const Color(0xFF2D2041),
                          backgroundImage: _getProfileImage(),
                          child: (_currentUser?.profileImageUrl == null || _currentUser!.profileImageUrl!.isEmpty) && _selectedImage == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 75, // Larger icon
                                )
                              : null,
                        ),
                  ),
                ),
                // Edit button - positioned like in the reference image
                Positioned(
                  right: 5,
                  bottom: 15,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F2B8), // Yellow background color
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF262135), // Dark border matching background
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined, // Outlined icon
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _currentUser?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montaga',
                    ),
                  ),
            const SizedBox(height: 80),

            // App Settings Title
            Padding(
              padding: const EdgeInsets.only(left: 26.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'App Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Montaga',
                  ),
                ),
              ),
            ),
            

            
            // App Settings Card - centered horizontally and vertically
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      title: 'Account Informations',
                      onTap: () {
                        Navigator.of(context).pushNamed('/account-info');
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _SettingsTile(
                      title: 'Notifications',
                      onTap: () {
                        Navigator.of(context).pushNamed('/notifications');
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _SettingsTile(
                      title: 'Text Size',
                      trailing: Text(
                        'Medium',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Montaga',
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            
            // Spacer to push card to center vertically
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 2,
        screenColor: Colors.purple,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Montaga',
          fontSize: 18,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white, size: 24),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    );
  }
} 