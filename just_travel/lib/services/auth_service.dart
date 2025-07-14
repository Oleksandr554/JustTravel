import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService { 
  static const String _userCredentialsPrefix = 'user_creds_';

 
  Future<void> registerUser(String loginIdentifier, String password) async {
    final prefs = await SharedPreferences.getInstance();
   
    await prefs.setString('$_userCredentialsPrefix${loginIdentifier}_password', password);
    print("User $loginIdentifier registered with password (unsafe storage).");
  }

 
  Future<bool> checkPassword(String loginIdentifier, String enteredPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('$_userCredentialsPrefix${loginIdentifier}_password');
    if (storedPassword == null) {
      print("No password found for user $loginIdentifier.");
      return false; 
    }
    final bool passwordsMatch = storedPassword == enteredPassword;
    if (!passwordsMatch) {
      print("Password mismatch for user $loginIdentifier.");
    }
    return passwordsMatch;
  }

  
  Future<void> deleteUserCredentials(String loginIdentifier) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('$_userCredentialsPrefix${loginIdentifier}_password');
     print("Credentials deleted for user $loginIdentifier.");
  }
}

final AuthService authService = AuthService();