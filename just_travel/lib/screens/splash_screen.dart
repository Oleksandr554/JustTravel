import 'dart:async';
import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../services/favorites_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showDetails = false;
  bool isLoginPressed = false;
  bool isSignUpPressed = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signupUsernameController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupGmailController = TextEditingController();
  String? _loginErrorText;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showDetails = true);
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _signupUsernameController.dispose();
    _signupPasswordController.dispose();
    _signupGmailController.dispose();
    super.dispose();
  }

  void _clearFieldsAndErrors() {
    _usernameController.clear();
    _passwordController.clear();
    _signupUsernameController.clear();
    _signupPasswordController.clear();
    _signupGmailController.clear();
    if (mounted) {
      setState(() {
        _loginErrorText = null;
      });
    }
  }

  void _handleLogin() async {
  final usernameLogin = _usernameController.text;
  final password = _passwordController.text;

  if (usernameLogin.isEmpty) {
    if (mounted) { setState(() { _loginErrorText = "Username cannot be empty."; }); }
    return;
  }
  if (password.isEmpty) {
     if (mounted) { setState(() { _loginErrorText = "Password cannot be empty."; }); }
     return;
  }


  
  if (usernameLogin == "admin" && password == "admin") {
     await userProfileService.loadProfileForExistingUser(usernameLogin);
     if (mounted) {
       setState(() { _loginErrorText = null; });
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(builder: (context) => HomeScreen(username: usernameLogin)),
       );
     }
     return; 
  }


  
  bool isAuthenticated = await authService.checkPassword(usernameLogin, password);

  if (isAuthenticated) {
    await userProfileService.loadProfileForExistingUser(usernameLogin);
    if (mounted) {
      setState(() { _loginErrorText = null; });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(username: usernameLogin)),
      );
    }
  } else {
    if (mounted) {
      setState(() { _loginErrorText = "Invalid username or password."; });
    }
  }
}

  void _handleSignUp() async {
  final signupLogin = _signupUsernameController.text; 
  final password = _signupPasswordController.text;
  final gmail = _signupGmailController.text;

  if (signupLogin.isNotEmpty && password.isNotEmpty && gmail.isNotEmpty) {
    
    await authService.registerUser(signupLogin, password);

    await userProfileService.initializeNewUserProfile(signupLogin, signupLogin, gmail);

    
    await favoritesService.clearFavoritesForUser(signupLogin);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(username: signupLogin)),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all sign up fields.")),
      );
    }
  }
}

  

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFA8D5BA),
      body: Stack(
        children: [
          
          if (_showDetails)
            Positioned(
              child: IgnorePointer(
                child: Container(
                  height: 383, 
                  decoration: const BoxDecoration(
                    gradient: LinearGradient( 
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF54655B),
                        Color(0xFFA8CBB7),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          AnimatedPositioned( 
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            top: _showDetails
                ? 100
                : MediaQuery.of(context).size.height / 2 - 150,
            left: (screenWidth - 150) / 2 + 10,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Image.asset("assets/welcome.png"),
            ),
          ),
          AnimatedOpacity( 
            duration: const Duration(milliseconds: 500),
            opacity: _showDetails ? 0 : 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 240),
                child: const Text(
                  "Just Travel",
                  style: TextStyle(
                    fontSize: 40,
                    fontFamily: "Pacifico",
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          if (_showDetails)
            Positioned( 
              bottom: 0,
              left: (screenWidth - 440) / 2,
              child: Container(
                width: 440, 
                height: 596, 
                decoration: const BoxDecoration( 
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column( 
                  children: [
                    const SizedBox(height: 27),
                    SizedBox(
                      width: 268,
                      height: 42,
                      child: Image.asset(
                        isLoginPressed
                            ? "assets/login.png"
                            : isSignUpPressed
                                ? "assets/Singup.png"
                                : "assets/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 55),
                    if (isLoginPressed) ...[
                      _buildInputField("User name", _usernameController),
                      _buildInputField("Password", _passwordController, isObscure: true),
                      if (_loginErrorText != null) 
                        Padding(
                          padding: const EdgeInsets.only(top: 0, bottom: 8.0), 
                          child: Text(
                            _loginErrorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const Text( 
                        "Don't remember your\nuser name or password?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'inter-bold',
                          fontSize: 16,
                          color: Color.fromRGBO(12, 108, 169, 1),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _handleLogin, 
                        child: _buildMainButton("Log in"), 
                      ),
                    ] else if (isSignUpPressed) ...[
                      _buildInputField("User name", _signupUsernameController),
                      _buildInputField("Password", _signupPasswordController, isObscure: true),
                      _buildInputField("Gmail", _signupGmailController, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _handleSignUp, 
                        child: Container( 
                          width: 350,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2E9DC),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[ 
                      GestureDetector(
                        onTap: () {
                          if(mounted) {
                            setState(() {
                            isLoginPressed = true;
                            isSignUpPressed = false;
                            _clearFieldsAndErrors(); 
                          });
                          }
                        },
                        child: _buildMainButton("Log in"), 
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          if(mounted){
                             setState(() {
                            isLoginPressed = false;
                            isSignUpPressed = true;
                            _clearFieldsAndErrors(); 
                          });
                          }
                        },
                        child: Container( 
                          width: 350,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2E9DC),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 45),
                      const Text(
                        "Or continue with",
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: "Inter",
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -5),
                            child: Image.asset(
                              "assets/apple.png",
                              width: 54,
                              height: 66,
                            ),
                          ),
                          const SizedBox(width: 60),
                          Image.asset(
                            "assets/google.png",
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(width: 50),
                          Image.asset(
                            "assets/facebook.png",
                            width: 60,
                            height: 60,
                          ),
                        ],
                      ),
                    ],
                    const Spacer(), 
                    const SizedBox(height: 20), 
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  

  Widget _buildInputField(String hintText, TextEditingController controller, {bool isObscure = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      width: 350, 
      height: 80, 
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      margin: const EdgeInsets.only(bottom: 20), 
      decoration: BoxDecoration( 
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Align( 
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center, 
          style: const TextStyle( 
            fontFamily: 'inter',
            fontSize: 24,
            color: Colors.black, 
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle( 
              fontFamily: 'inter',
              fontSize: 24,
              color: Colors.black54,
            ),
            border: InputBorder.none, 
            isDense: true, 
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainButton(String label) {
    return Container(
      width: 350,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF4A261),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.black,
          fontFamily: "Inter",
        ),
      ),
    );
  }
}