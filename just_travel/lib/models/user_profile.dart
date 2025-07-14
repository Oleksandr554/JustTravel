
class UserProfile {
  String username; 
  String email;  
  String? imagePath;

  UserProfile({required this.username, required this.email, this.imagePath});

 
  factory UserProfile.initial(String loginUsername, [String? initialEmail]) {
    return UserProfile(
      username: loginUsername,
      email: initialEmail ?? "${loginUsername.toLowerCase().replaceAll(' ', '_')}@example.com",
      imagePath: null,
    );
  }
}