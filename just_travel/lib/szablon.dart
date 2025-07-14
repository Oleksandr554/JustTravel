import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const JustTravelApp());


class JustTravelApp extends StatelessWidget {
  const JustTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // SplashScreen не потребує username на вході
    );
  }
}

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

  void _handleLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password == "admin") { 
      if (mounted) {
        setState(() { _loginErrorText = null; });
        Navigator.pushReplacement( 
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(username: username)), 
        );
      }
    } else if (username.isEmpty) {
      if (mounted) { setState(() { _loginErrorText = "Username cannot be empty."; }); }
    } else {
      if (mounted) { setState(() { _loginErrorText = "Invalid username or password."; }); }
    }
  }
  
  void _handleSignUp() {
    final username = _signupUsernameController.text;
    final password = _signupPasswordController.text;
    final gmail = _signupGmailController.text;

    if (username.isNotEmpty && password.isNotEmpty && gmail.isNotEmpty) {
       if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: username)), 
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
                          setState(() {
                            isLoginPressed = true;
                            isSignUpPressed = false;
                            _clearFieldsAndErrors(); 
                          });
                        },
                        child: _buildMainButton("Log in"), 
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isLoginPressed = false;
                            isSignUpPressed = true;
                            _clearFieldsAndErrors(); 
                          });
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

// HomeScreen - залишається без змін, він вже приймає username
class HomeScreen extends StatefulWidget {
  final String username; 

  const HomeScreen({super.key, required this.username}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedChipIndex = 0;

  @override
  void initState() {
    super.initState();
    // Важливо встановити selectedIndex тут, якщо HomeScreen є початковим після логіну
    _selectedIndex = 0; 
    favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFavoriteStatus(String journeyId) {
    favoritesService.toggleFavorite(journeyId);
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index && index != 0) return; // Уникаємо зайвих переходів, крім головної

    // Оновлюємо _selectedIndex ТІЛЬКИ ЯКЩО це не перехід на поточну сторінку (крім HomeScreen)
    // Або якщо ми завжди хочемо оновити стан, то робимо setState тут
    if (_selectedIndex != index) {
       if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
    
    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: widget.username);
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username); // <--- ВИПРАВЛЕНО
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username); // <--- ВИПРАВЛЕНО
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username); // <--- ВИПРАВЛЕНО
        break;
      default:
        nextPage = HomeScreen(username: widget.username); // За замовчуванням
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    // _selectedIndex тепер керується _onNavIndexChanged та initState
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${widget.username}", 
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Welcome to JustTravel",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)), 
                      );
                    },
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/profile.png"),
                      radius: 34,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8D5BA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 110, vertical: 12),
                child: Text(
                  "+ Add journey",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'inter',
                      fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    "Journeys",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: List.generate(4, (idx) { // Змінив 'index' на 'idx' щоб уникнути конфлікту з _onNavIndexChanged
                  final labels = ["Ongoing", "Past", "Draft", "Upcoming"];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChipIndex = idx;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedChipIndex == idx
                            ? const Color(0xFFA8D5BA)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          color: _selectedChipIndex == idx ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter-bold',
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 44),
            Expanded(
              child: () {
                final List<List<Map<String, String>>> journeysByCategory = [
                  JourneyData.allJourneys.where((j) => j['status'] == 'Ongoing').toList(),
                  JourneyData.allJourneys.where((j) => j['status'] == 'Past').toList(),
                  JourneyData.allJourneys.where((j) => j['status'] == 'Draft').toList(),
                  JourneyData.allJourneys.where((j) => j['status'] == 'Upcoming').toList(),
                ];

                final journeys = journeysByCategory[_selectedChipIndex];

                if (journeys.isEmpty) {
                  return const Center(
                    child: Text(
                      "No journeys available.",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return PageView.builder(
                  controller: PageController(viewportFraction: 0.8),
                  itemCount: journeys.length,
                  itemBuilder: (context, pageViewIndex) { // Змінив 'index' на 'pageViewIndex'
                    final journey = journeys[pageViewIndex];
                    final String journeyId = journey['id']!;
                    final bool isFav = favoritesService.isFavorite(journeyId);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: AssetImage(journey['image']!),
                            fit: BoxFit.fill,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 15,
                              right: 15,
                              bottom: 75,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        journey['country']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        journey['city']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    journey['date']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'inter',
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 15,
                              right: 15,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(30)),
                                child: Material(
                                  color: Colors.white54,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JourneyDetailScreen(
                                            journeyId: journeyId,
                                            journeyImage: journey['image']!,
                                            city: journey['city']!,
                                            country: journey['country']!,
                                            date: journey['date']!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 100),
                                            child: Text(
                                              "See more",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Inter-Bold',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 7),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.white,
                                              child: const Icon(Icons.arrow_forward,
                                                  size: 25, color: Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 20,
                              child: GestureDetector(
                                onTap: () {
                                  _toggleFavoriteStatus(journeyId);
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white54,
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.black : Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              left: 20,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white54,
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex, 
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}


// JourneyDetailScreen - залишається без змін
class JourneyDetailScreen extends StatefulWidget {
  final String journeyId; 
  final String journeyImage;
  final String city;
  final String country;
  final String date;

  const JourneyDetailScreen({
    super.key,
    required this.journeyId, 
    required this.journeyImage,
    required this.city,
    required this.country,
    required this.date,
  });

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  final List<Map<String, dynamic>> memoryImages = [
    {"image": "assets/img1.png", "isLiked": false},
    {"image": "assets/img2.png", "isLiked": false},
    {"image": "assets/img3.png", "isLiked": false},
    {"image": "assets/img2.png", "isLiked": false},
  ];

  @override
  void initState() {
    super.initState();
    favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
      });
    }
  }
  
  void _toggleLike(int index) {
    setState(() {
      memoryImages[index]['isLiked'] = !memoryImages[index]['isLiked'];
    });
  }

  void _toggleMainFavorite() {
    favoritesService.toggleFavorite(widget.journeyId);
  }
  

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    const double whitePanelHeight = 596;
    const double whitePanelWidth = 440;

    final double actualDisplayPanelWidth = min(screenWidth, whitePanelWidth);

    const double imageScaleFactor = 1.2;
    const double imageOffsetY = -200.0;

    final bool isMainFavorite = favoritesService.isFavorite(widget.journeyId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                maxWidth: screenWidth * imageScaleFactor * 1.5,
                maxHeight: screenHeight * imageScaleFactor * 1.5,
                child: Transform.translate(
                  offset: Offset(0, imageOffsetY),
                  child: Transform.scale(
                    scale: imageScaleFactor,
                    alignment: Alignment.center,
                    child: Image.asset(
                      widget.journeyImage,
                      width: screenWidth,
                      height: screenHeight,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey,
                        child: Center(child: Text('Image not found: ${widget.journeyImage}')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            right: 20,
            child: GestureDetector(
              onTap: _toggleMainFavorite,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMainFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.black,
                  size: 24
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: (screenWidth - actualDisplayPanelWidth) / 2,
            right: (screenWidth - actualDisplayPanelWidth) / 2,
            child: Container(
              width: actualDisplayPanelWidth,
              height: whitePanelHeight,
              padding: const EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Expanded( 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.city,
                                style: const TextStyle(
                                  fontFamily: 'Inter-Bold',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                widget.country,
                                style: const TextStyle(
                                  fontFamily: 'Inter-bold', 
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 45.0), 
                          child: Text(
                            widget.date, 
                            style: const TextStyle(
                              fontFamily: 'Inter', 
                              fontSize: 16,
                              color: Colors.black54, 
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text(
                        "Praesent luctus enim sed felis pulvinar fermentum. Suspendisse erat mauris, euismod vel condimentum id, molestie id elit ...",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter'
                        ),
                      ),
                    ),
                    const Text(
                      "Read more",
                      style: TextStyle(
                        fontFamily: 'Inter-Bold',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Yours memory",
                          style: TextStyle(
                            fontFamily: 'Inter-Bold',
                            fontSize: 24,
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                          },
                          child: const Text(
                            "See all",
                            style: TextStyle(
                              fontFamily: 'Inter-Bold',
                              fontSize: 20,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 264,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: memoryImages.length,
                        itemBuilder: (context, index) {
                          final memoryItem = memoryImages[index];
                          return Container(
                            width: 286,
                            height: 264,
                            margin: const EdgeInsets.only(right: 15),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    memoryItem['image'],
                                    fit: BoxFit.cover,
                                    width: 286,
                                    height: 264,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Text("Image")),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: () => _toggleLike(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        memoryItem['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// GalleryScreen - ТЕПЕР ПРИЙМАЄ USERNAME
class GalleryScreen extends StatefulWidget {
  final String username; // <--- ДОДАНО
  const GalleryScreen({super.key, required this.username}); // <--- ОНОВЛЕНО

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _selectedIndex = 1; // Початковий індекс для GalleryScreen

  @override
  void initState() {
    super.initState();
    // Встановлюємо selectedIndex відповідно до поточної сторінки
    _selectedIndex = 1; 
    favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFavoriteStatus(String journeyId) {
    // setState тут не обов'язковий, якщо _onFavoritesChanged оновлює UI
    favoritesService.toggleFavorite(journeyId);
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) return; // Уникаємо переходу на поточну сторінку

    if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
    }

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      default:
        nextPage = HomeScreen(username: widget.username); // За замовчуванням
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> galleryItems = [
      // Ваші galleryItems...
       {
        "id": "usa_texas",
        "image": "assets/texas.png",
        "city": "Texas",
        "country": "USA",
        "date": "07.13 - 07.27",
      },
      {
        "id": "france_paris",
        "image": "assets/paris.png",
        "city": "Paris",
        "country": "France",
        "date": "08.01 - 08.10",
      },
      {
        "id": "japan_tokyo",
        "image": "assets/tokyo.png",
        "city": "Tokyo",
        "country": "Japan",
        "date": "09.05 - 09.20",
      },
      {
        "id": "thailand_phuket",
        "image": "assets/big_image.png",
        "city": "Phuket",
        "country": "Thailand",
        "date": "10.01 - 10.15",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Galeria",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)), // <--- ПЕРЕДАЄМО USERNAME
                      );
                    },
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/profile.png"),
                      radius: 34,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: galleryItems.length,
                itemBuilder: (context, index) {
                  final item = galleryItems[index];
                  final String journeyId = item['id']!;
                  final bool isFav = favoritesService.isFavorite(journeyId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JourneyDetailScreen(
                              journeyId: journeyId,
                              journeyImage: item['image']!,
                              city: item['city']!,
                              country: item['country']!,
                              date: item['date']!,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              item['image']!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Text('Img N/A')),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['city']!,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['country']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 70),
                                    child: GestureDetector(
                                      onTap: () {
                                        _toggleFavoriteStatus(journeyId);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5), // Змінено на Color(0xFFF5F5F5)
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            size: 20,
                                            color: isFav ? Colors.black : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['date']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}


// FavouritePage - ТЕПЕР ПРИЙМАЄ USERNAME
class FavouritePage extends StatefulWidget {
  final String username; // <--- ДОДАНО
  const FavouritePage({super.key, required this.username}); // <--- ОНОВЛЕНО

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  int _selectedIndex = 2; // Початковий індекс для FavouritePage
  int _currentBigImageIndex = 0;
  Timer? _timer;

  final List<String> bigImages = [
    "assets/big_image.png", "assets/img1.png", "assets/img2.png",
    "assets/img3.png", "assets/img4.png", "assets/img5.png",
    "assets/img6.png", "assets/img7.png",
  ];

  final List<String> smallImages = [
    "assets/img1.png", "assets/img2.png", "assets/img3.png",
    "assets/img4.png", "assets/img5.png", "assets/img6.png",
    "assets/img7.png",
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 2;
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted) { // Додано перевірку mounted
        setState(() {
          _currentBigImageIndex = (_currentBigImageIndex + 1) % bigImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) return;

    if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
    }

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      default:
        nextPage = HomeScreen(username: widget.username);
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Favorite",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)), // <--- ПЕРЕДАЄМО USERNAME
                      );
                    },
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/profile.png"),
                      radius: 34,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 410,
              height: 388,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: AssetImage(bigImages[_currentBigImageIndex]),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.favorite, color: Colors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: List.generate(smallImages.length, (index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            smallImages[index],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Positioned(
                          bottom: 6,
                          left: 6,
                          child: Icon(Icons.favorite, color: Colors.white, size: 16),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}


// StatisticPage - ТЕПЕР ПРИЙМАЄ USERNAME
class StatisticPage extends StatefulWidget {
  final String username; // <--- ДОДАНО
  const StatisticPage({super.key, required this.username}); // <--- ОНОВЛЕНО

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedIndex = 3; // Початковий індекс для StatisticPage
  late Map<String, int> _calculatedTripStatusData;
  late List<Map<String, dynamic>> _calculatedMostVisitedCountries;
  late List<Map<String, dynamic>> _calculatedActivityPerYear;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 3;
    _calculateStatistics();
  }

  void _calculateStatistics() {
    _calculatedTripStatusData = {
      'Ongoing': 0, 'Draft': 0, 'Past': 0, 'Upcoming': 0,
    };
    for (var journey in JourneyData.allJourneys) {
      final status = journey['status'];
      if (status != null && _calculatedTripStatusData.containsKey(status)) {
        _calculatedTripStatusData[status] = _calculatedTripStatusData[status]! + 1;
      }
    }

    Map<String, int> countryVisits = {};
    for (var journey in JourneyData.allJourneys) {
      final country = journey['country'];
      if (country != null) {
        countryVisits[country] = (countryVisits[country] ?? 0) + 1;
      }
    }
    var sortedCountries = countryVisits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _calculatedMostVisitedCountries = sortedCountries.take(5).map((entry) {
      return {'name': entry.key, 'visits': entry.value, 'color': const Color(0xFFF44336)};
    }).toList();

    Map<int, int> activityCountPerYear = {};
    for (var journey in JourneyData.allJourneys) {
      final dateRange = journey['date'];
      if (dateRange != null) {
        try {
          final startDateStr = dateRange.split(' - ')[0];
          final year = int.parse("20${startDateStr.split('.')[0]}");
          activityCountPerYear[year] = (activityCountPerYear[year] ?? 0) + 1;
        } catch (e) {
          print("Error parsing date for activity: $dateRange, error: $e");
        }
      }
    }
    final yearColors = [
      const Color(0xFFCDB4DB), const Color(0xFF3E4A53), const Color(0xFF80D8EA),
      const Color(0xFFFFB74D), const Color(0xFFE57373),
    ];
    int colorIndex = 0;
    _calculatedActivityPerYear = activityCountPerYear.entries
      .map((entry) {
        final color = yearColors[colorIndex % yearColors.length];
        colorIndex++;
        return {'year': entry.key, 'activity': entry.value.toDouble(), 'color': color};
      })
      .toList()
      ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
  }

  void _onNavIndexChanged(int index) {
     if (_selectedIndex == index) {
      // Якщо ми намагаємося перейти на поточну сторінку статистики,
      // просто перераховуємо статистику (якщо це має сенс для вашого додатка)
      if (index == 3) {
        if (mounted) {
          setState(() {
            _calculateStatistics();
          });
        }
      }
      return;
    }


    if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
    }
    
    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username); // <--- ПЕРЕДАЄМО USERNAME
        break;
      default:
        nextPage = HomeScreen(username: widget.username);
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalJourneys = _calculatedTripStatusData.values.fold(0, (sum, item) => sum + item);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Statistic",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)), // <--- ПЕРЕДАЄМО USERNAME
                      );
                    },
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/profile.png"),
                      radius: 34,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 219,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 18.0, bottom: 10.0),
                      child: Text(
                        "All your trips",
                        style: TextStyle(fontFamily: 'Inter-bold', fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: CustomPaint(
                                painter: PieChartPainter(data: _calculatedTripStatusData),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        totalJourneys.toString(),
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Journeys",
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15.0, top:10, bottom:10, left: 5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _calculatedTripStatusData.entries.map((entry) {
                                  return _buildLegendItem(
                                      _getColorForStatus(entry.key), entry.key, entry.value);
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 180, 
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Most visited country",
                        style: TextStyle(fontFamily: 'Inter-Bold', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _calculatedMostVisitedCountries.isEmpty
                          ? const Center(child: Text("No country data available."))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _calculatedMostVisitedCountries.map((countryData) {
                                final maxVisits = _calculatedMostVisitedCountries.map<int>((c) => c['visits']).fold(0, (prev, curr) => curr > prev ? curr : prev);
                                return _buildCountryVisitBar(
                                  countryData['name'],
                                  countryData['visits'],
                                  maxVisits == 0 ? 0.0 : (countryData['visits'] / maxVisits),
                                  countryData['color'],
                                );
                              }).toList(),
                            ),
                      ),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 20),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Activity per year",
                        style: TextStyle(fontFamily: 'Inter-Bold', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _calculatedActivityPerYear.isEmpty
                         ? const Center(child: Text("No activity data available."))
                         : LayoutBuilder(
                            builder: (context, constraints) {
                              final double availableHeightForBars = constraints.maxHeight - 30;
                              final maxActivity = _calculatedActivityPerYear.map<double>((y) => y['activity']).fold(0.0, (prev, curr) => curr > prev ? curr : prev);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _calculatedActivityPerYear.map((yearData) {
                                  return _buildActivityBar(
                                    context,
                                    yearData['year'].toString(),
                                    yearData['activity'],
                                    maxActivity,
                                    yearData['color'],
                                    availableHeightForBars,
                                  );
                                }).toList(),
                              );
                            }
                          ),
                      ),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }

  Widget _buildStatisticCard({required double width, required double height, required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.black54)),
          ],
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)
        ),
      ],
    );
  }

   Color _getColorForStatus(String status) {
    switch (status) {
      case 'Ongoing': return const Color(0xFFE53935); 
      case 'Draft': return const Color(0xFF7CB342);   
      case 'Past': return const Color(0xFF1E88E5);    
      case 'Upcoming': return const Color(0xFFFFB300); 
      default: return Colors.grey;
    }
  }

 Widget _buildCountryVisitBar(String country, int visits, double progress, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 65, 
          child: Text(
            country,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey[600]), 
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6, 
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (progress > 0) 
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: barColor, 
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 25, 
          child: Text(
            visits.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

 Widget _buildActivityBar(BuildContext context, String year, double activity, double maxActivity, Color color, double availableHeight) {
    final barHeightPercentage = maxActivity == 0 ? 0.0 : (activity / maxActivity);
    final barHeight = barHeightPercentage * (availableHeight * 0.9); 
    final double totalHorizontalPadding = 40; 
    final int numberOfBars = _calculatedActivityPerYear.length; 
    final double spacingBetweenBars = 15.0; 
    final double totalSpacing = (numberOfBars - 1) * spacingBetweenBars;
    final double chartContainerWidth = MediaQuery.of(context).size.width - 40 - totalHorizontalPadding;
    final double barWidth = (chartContainerWidth - totalSpacing) / numberOfBars * 0.8; 


    return Column(
      mainAxisSize: MainAxisSize.min, 
      mainAxisAlignment: MainAxisAlignment.end, 
      children: [
        Container(
          width: barWidth > 0 ? barWidth : 10, 
          height: barHeight.isFinite && barHeight > 5 ? barHeight : 5.0, 
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          year,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}


// ProfileScreen - залишається без змін, він вже приймає username
class ProfileScreen extends StatefulWidget {
  final String username; 

  const ProfileScreen({super.key, required this.username}); 

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20, top: statusBarHeight > 20 ? 10 : 20),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        )
                      ]
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile.png"), 
            ),
            const SizedBox(height: 10),
            Text(
              widget.username, 
              style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text( 
              "${widget.username.toLowerCase().replaceAll(' ', '_')}@example.com", 
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.black54.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2D8B6),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Edit profile",
                style: TextStyle(fontFamily: 'Inter', fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: screenWidth * 0.9 > 410 ? 410 : screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileOptionRow(
                    icon: Icons.calendar_today_outlined,
                    text: "Joined",
                    trailing: const Text("2022.03.01", style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.grey)),
                    onTap: () {},
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.notifications_none_outlined,
                    text: "Notification",
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    onTap: () {
                       setState(() {
                          _notificationsEnabled = !_notificationsEnabled;
                        });
                    },
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.language_outlined,
                    text: "Support",
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                    },
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.settings_outlined,
                    text: "Settings",
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                    },
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.logout_outlined,
                    text: "Logout",
                    textColor: const Color(0xFFAD1010),
                    onTap: () {
                       Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const SplashScreen()), 
                        (Route<dynamic> route) => false,
                      );
                    },
                    hideDivider: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptionRow({
    required IconData icon,
    required String text,
    Widget? trailing,
    VoidCallback? onTap,
    Color textColor = Colors.black87,
    bool hideDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: textColor == const Color(0xFFAD1010) ? textColor.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: textColor == const Color(0xFFAD1010) ? textColor : Colors.black54),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: textColor, fontWeight: FontWeight.w500),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            if (!hideDivider) const SizedBox(height: 12),
            if (!hideDivider) Divider(height: 1, color: Colors.grey.shade300, indent: 45, endIndent: 0,)
          ],
        ),
      ),
    );
  }
}

// PieChartPainter - залишається без змін
class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  PieChartPainter({required this.data});

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Ongoing': return const Color(0xFFE53935); 
      case 'Draft': return const Color(0xFF7CB342);   
      case 'Past': return const Color(0xFF1E88E5);    
      case 'Upcoming': return const Color(0xFFFFB300); 
      default: return Colors.grey;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.80; 
    final strokeWidth = radius * 0.1; 
    final innerRadius = radius - strokeWidth;

    double startAngle = -pi / 2; 

    data.forEach((status, value) {
      final sweepAngle = (value / total) * 2 * pi;
      final paint = Paint()
        ..color = _getColorForStatus(status)
        ..style = PaintingStyle.stroke 
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius + strokeWidth / 2), 
        startAngle,
        sweepAngle - 0.03, 
        false, 
        paint,
      );
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      return oldDelegate.data != data;
    }
    return true;
  }
}

// JourneyData, FavoritesService, NavigationBarWidget, JourneyChip - залишаються без змін
class JourneyData {
  static final List<Map<String, String>> allJourneys = [
    {
      "id": "usa_texas", "country": "USA", "city": "Texas",
      "date": "25.07.13 - 25.07.27", "image": "assets/texas.png", "status": "Ongoing"
    },
    {
      "id": "france_paris", "country": "France", "city": "Paris",
      "date": "25.08.01 - 25.08.10", "image": "assets/paris.png", "status": "Ongoing"
    },
    {
      "id": "japan_tokyo", "country": "Japan", "city": "Tokyo",
      "date": "25.09.05 - 25.09.20", "image": "assets/tokyo.png", "status": "Ongoing"
    },
    {
      "id": "thailand_phuket", "country": "Thailand", "city": "Phuket",
      "date": "23.03.25 - 23.04.10", "image": "assets/big_image.png", "status": "Past"
    },
  ];
}

class FavoritesService extends ChangeNotifier {
  final Set<String> _favoriteJourneyIds = {};
  Set<String> get favoriteJourneyIds => _favoriteJourneyIds;

  bool isFavorite(String journeyId) => _favoriteJourneyIds.contains(journeyId);

  void toggleFavorite(String journeyId) {
    if (_favoriteJourneyIds.contains(journeyId)) {
      _favoriteJourneyIds.remove(journeyId);
    } else {
      _favoriteJourneyIds.add(journeyId);
    }
    notifyListeners();
  }
}
final FavoritesService favoritesService = FavoritesService();

class NavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const NavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  final List<String> icons = const [
    "assets/home.png", "assets/galerie.png",
    "assets/likes.png", "assets/statistik.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 50, right: 50, top: 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFA8D5BA),
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(icons.length, (index) {
            final bool isActive = selectedIndex == index;
            return GestureDetector(
              onTap: () => onIndexChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Image.asset(
                        icons[index],
                        width: 70, // Розмір іконки може потребувати корекції
                        height: 30, // Розмір іконки може потребувати корекції
                        color: isActive ? Colors.black : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class JourneyChip extends StatelessWidget {
  final String label;
  final bool selected;

  const JourneyChip({super.key, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA8D5BA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}