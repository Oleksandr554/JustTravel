import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileService extends ChangeNotifier {
  
  static const String _userPrefix = 'user_profile_';
  static const String _keyUsernameSuffix = '_username';
  static const String _keyEmailSuffix = '_email';
  static const String _keyImagePathSuffix = '_image_path';

  UserProfile? _currentUserProfile;
  UserProfile? get currentUserProfile => _currentUserProfile;

  
  String? _currentLoginIdentifier;
  String? get currentLoginIdentifier => _currentLoginIdentifier; 
  

  
  Future<void> loadProfileForExistingUser(String loginIdentifier) async {
    _currentLoginIdentifier = loginIdentifier;
    final prefs = await SharedPreferences.getInstance();

    final String usernameKey = '$_userPrefix${_currentLoginIdentifier}$_keyUsernameSuffix';
    final String emailKey = '$_userPrefix${_currentLoginIdentifier}$_keyEmailSuffix';
    final String imagePathKey = '$_userPrefix${_currentLoginIdentifier}$_keyImagePathSuffix';

    _currentUserProfile = UserProfile(
      username: prefs.getString(usernameKey) ?? loginIdentifier, 
      email: prefs.getString(emailKey) ?? "${loginIdentifier.toLowerCase().replaceAll(' ', '_')}@example.com",
      imagePath: prefs.getString(imagePathKey),
    );
    notifyListeners();
  }

  
  Future<void> initializeNewUserProfile(String loginIdentifier, String initialDisplayName, String initialEmail) async {
    _currentLoginIdentifier = loginIdentifier;
    _currentUserProfile = UserProfile(
      username: initialDisplayName,
      email: initialEmail,        
      imagePath: null,            
    );
    
    await updateProfile(_currentUserProfile!);
    
  }


  Future<void> updateProfile(UserProfile newProfile) async {
    if (_currentLoginIdentifier == null) {
      print("UserProfileService Error: _currentLoginIdentifier is null. Cannot update profile.");
      
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    final String usernameKey = '$_userPrefix${_currentLoginIdentifier}$_keyUsernameSuffix';
    final String emailKey = '$_userPrefix${_currentLoginIdentifier}$_keyEmailSuffix';
    final String imagePathKey = '$_userPrefix${_currentLoginIdentifier}$_keyImagePathSuffix';

    await prefs.setString(usernameKey, newProfile.username);
    await prefs.setString(emailKey, newProfile.email);

    if (newProfile.imagePath != null && newProfile.imagePath!.isNotEmpty) {
      await prefs.setString(imagePathKey, newProfile.imagePath!);
    } else {
      await prefs.remove(imagePathKey);
    }

    _currentUserProfile = newProfile;
    notifyListeners();
  }

  Future<String?> saveProfileImage(XFile imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      final newPath = p.join(directory.path, fileName);
      final File newImage = await File(imageFile.path).copy(newPath);
      return newImage.path;
    } catch (e) {
      print("Error saving profile image: $e");
      return null;
    }
  }

  
  Future<void> clearCurrentProfileData() async {
    if (_currentLoginIdentifier == null) {
      _currentUserProfile = null;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final String usernameKey = '$_userPrefix${_currentLoginIdentifier}$_keyUsernameSuffix';
    final String emailKey = '$_userPrefix${_currentLoginIdentifier}$_keyEmailSuffix';
    final String imagePathKey = '$_userPrefix${_currentLoginIdentifier}$_keyImagePathSuffix';

    await prefs.remove(usernameKey);
    await prefs.remove(emailKey);
    await prefs.remove(imagePathKey);

    _currentUserProfile = null;
    
    notifyListeners();
  }
}

final UserProfileService userProfileService = UserProfileService();