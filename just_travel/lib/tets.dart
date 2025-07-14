import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; 
import 'package:intl/intl.dart'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:convert';

void main() => runApp(const JustTravelApp());


class JustTravelApp extends StatelessWidget {
  const JustTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}



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

class UserProfileService extends ChangeNotifier {
  
  static const String _userPrefix = 'user_profile_';
  static const String _keyUsernameSuffix = '_username';
  static const String _keyEmailSuffix = '_email';
  static const String _keyImagePathSuffix = '_image_path';

  UserProfile? _currentUserProfile;
  UserProfile? get currentUserProfile => _currentUserProfile;

  
  String? _currentLoginIdentifier;

  
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

class Journey {
  final int? id;
  final String userId;
  String mainImagePath;
  DateTime startDate;
  DateTime endDate;
  String city;
  String country;
  String description;
  List<String> additionalImagePaths;
  String status;

  Journey({
    this.id,
    required this.userId,
    required this.mainImagePath,
    required this.startDate,
    required this.endDate,
    required this.city,
    required this.country,
    required this.description,
    this.additionalImagePaths = const [],
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'mainImagePath': mainImagePath,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'city': city,
      'country': country,
      'description': description,
      'additionalImagePaths': jsonEncode(additionalImagePaths),
      'status': status,
    };
  }

  factory Journey.fromMap(Map<String, dynamic> map) {
    return Journey(
      id: map['id'],
      userId: map['userId'], 
      mainImagePath: map['mainImagePath'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      city: map['city'],
      country: map['country'],
      description: map['description'],
      additionalImagePaths: (jsonDecode(map['additionalImagePaths']) as List<dynamic>).cast<String>(),
      status: map['status'],
    );
  }

  String get stringId => id.toString();
}


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String dbPath = p.join(await getDatabasesPath(), 'just_travel_v2.db'); 
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
     
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE journeys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL, 
        mainImagePath TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        description TEXT NOT NULL,
        additionalImagePaths TEXT,
        status TEXT NOT NULL
      )
    ''');
  }


  Future<int> insertJourney(Journey journey) async {
    final db = await database;
    Map<String, dynamic> journeyMap = journey.toMap();
    if (journeyMap['id'] == null) {
      journeyMap.remove('id');
    }
    return await db.insert('journeys', journeyMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  
  Future<List<Journey>> getJourneysForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journeys',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    return List.generate(maps.length, (i) {
      return Journey.fromMap(maps[i]);
    });
  }

  Future<Journey?> getJourneyById(int id, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journeys',
      where: 'id = ? AND userId = ?', 
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) {
      return Journey.fromMap(maps.first);
    }
    return null;
  }

  
  Future<void> deleteJourneysForUser(String userId) async {
    final db = await database;
    await db.delete(
      'journeys',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print("Deleted all journeys for user $userId");
  }

  
  Future<void> deleteAllDataAndRecreate() async {
     String path = p.join(await getDatabasesPath(), 'just_travel_v2.db');
     await deleteDatabase(path);
     _database = null;
     await database;
     print("Database deleted and recreated.");
  }
}



class AddJourneyScreen extends StatefulWidget {
  final String currentUserId; 

  const AddJourneyScreen({super.key, required this.currentUserId});

  @override
  _AddJourneyScreenState createState() => _AddJourneyScreenState();
}

class _AddJourneyScreenState extends State<AddJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  XFile? _mainImage;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _additionalImages = [];

  bool _isLoading = false;

  Future<String> _saveImagePermanently(XFile imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = p.basename(imageFile.path); 
    final newPath = p.join(directory.path, fileName); 
    final File newImage = await File(imageFile.path).copy(newPath);
    return newImage.path;
  }

  Future<void> _pickImage(ImageSource source, {bool isMain = true}) async {
    if (isMain) {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null && mounted) {
        setState(() {
          _mainImage = pickedFile;
        });
      }
    } else {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
      if (mounted) {
        setState(() {
          _additionalImages.addAll(pickedFiles);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_mainImage == null) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a main image.')),
            );
        }
        return;
      }
      if (_startDate == null || _endDate == null) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select start and end dates.')),
            );
         }
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End date cannot be earlier than start date.')),
            );
         }
        return;
      }

      if(mounted) setState(() => _isLoading = true);

      try {
        String mainImagePath = await _saveImagePermanently(_mainImage!);
        List<String> additionalImagePaths = [];
        for (XFile img in _additionalImages) {
          additionalImagePaths.add(await _saveImagePermanently(img));
        }
        
        String status;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (_endDate!.isBefore(today)) {
            status = "Past";
        } else if (_startDate!.isAfter(today)) {
            status = "Upcoming";
        } else { 
            status = "Ongoing";
        }

        final newJourney = Journey(
          userId: widget.currentUserId,
          mainImagePath: mainImagePath,
          startDate: _startDate!,
          endDate: _endDate!,
          city: _cityController.text,
          country: _countryController.text,
          description: _descriptionController.text,
          additionalImagePaths: additionalImagePaths,
          status: status,
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.insertJourney(newJourney);

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journey added successfully!')),
            );
            Navigator.of(context).pop(true);
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add journey: $e')),
            );
         }
      } finally {
        if (mounted) {
            setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildImagePickerWidget({required bool isMain}) { 
    Widget imageDisplay;
    if (isMain) {
      imageDisplay = _mainImage == null
          ? const Icon(Icons.image, size: 50, color: Colors.grey)
          : Image.file(File(_mainImage!.path), height: 100, width: double.infinity, fit: BoxFit.cover);
    } else {
      imageDisplay = _additionalImages.isEmpty
          ? const Icon(Icons.photo_library, size: 50, color: Colors.grey)
          : SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _additionalImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_additionalImages[index].path), height: 100, width: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _additionalImages.removeAt(index);
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10)
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isMain ? 'Main Image*' : 'Additional Images (Optional)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceDialog(isMain: isMain),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: imageDisplay,
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog({required bool isMain}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isMain ? 'Select Main Image' : 'Select Additional Images'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, isMain: isMain);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, isMain: isMain);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Journey'),
        backgroundColor: const Color(0xFFA8D5BA),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildImagePickerWidget(isMain: true),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a city' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.public)),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a country' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _startDate == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(_startDate!),
                                style: TextStyle(fontSize: 16, color: _startDate == null ? Colors.grey.shade700 : Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(_endDate!),
                                 style: TextStyle(fontSize: 16, color: _endDate == null ? Colors.grey.shade700 : Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('End date cannot be earlier than start date.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildImagePickerWidget(isMain: false),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A261),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: const Text('Add Journey', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
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

class HomeScreen extends StatefulWidget {
  final String username; 

  const HomeScreen({super.key, required this.username}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedChipIndex = 0;
  UserProfile? _profileData;

  List<Journey> _allJourneys = [];
  bool _isLoading = true;
  Set<String> _currentUserFavorites = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;

    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged);

    
    favoritesService.addListener(_onFavoritesChanged);

    _loadJourneys();
    _loadInitialFavorites();
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged);
    
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onProfileDataChanged() {
    if (mounted) {
    
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
      
    }
  }

  Future<void> _loadJourneys() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();
   
    final journeysFromDb = await dbHelper.getJourneysForUser(widget.username);
    if (mounted) {
      setState(() {
        _allJourneys = journeysFromDb;
        _isLoading = false;
      });
    }
  }

  
  void _onFavoritesChanged() {
    _loadInitialFavorites(); 
  }

  Future<void> _loadInitialFavorites() async {
    if (!mounted) return;
    
    _currentUserFavorites = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    if (mounted) {
      setState(() {}); 
    }
  }

  void _toggleFavoriteStatus(String journeyId) {
   
    favoritesService.toggleFavorite(journeyId, widget.username);
   
   
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index && index != 0) return;

  
    final String currentUserLoginId = widget.username;

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
        nextPage = HomeScreen(username: currentUserLoginId);
        break;
      case 1:
        nextPage = GalleryScreen(username: currentUserLoginId);
        break;
      case 2:
        nextPage = FavouritePage(username: currentUserLoginId);
        break;
      case 3:
        nextPage = StatisticPage(username: currentUserLoginId);
        break;
      default:
        nextPage = HomeScreen(username: currentUserLoginId);
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${_profileData?.username ?? widget.username}",
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
                    child: CircleAvatar(
                      radius: 34,
                      backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                          ? FileImage(File(_profileData!.imagePath!))
                          : const AssetImage("assets/profile1.png") as ImageProvider,
                      onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                          ? (exception, stackTrace) {
                              print('Error loading profile image in HomeScreen: ${_profileData!.imagePath} $exception');
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                
                final String currentUserId = widget.username;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddJourneyScreen(currentUserId: currentUserId)),
                );
                if (result == true && mounted) {
                  _loadJourneys();
                  _loadInitialFavorites();
                }
              },
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
                children: List.generate(4, (idx) {
                  final labels = ["Ongoing", "Past", "Draft", "Upcoming"];
                  return GestureDetector(
                    onTap: () {
                      if (mounted) setState(() => _selectedChipIndex = idx);
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
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final List<List<Journey>> journeysByCategory = [
                        _allJourneys.where((j) => j.status == 'Ongoing').toList(),
                        _allJourneys.where((j) => j.status == 'Past').toList(),
                        _allJourneys.where((j) => j.status == 'Draft').toList(),
                        _allJourneys.where((j) => j.status == 'Upcoming').toList(),
                      ];

                      final journeys = journeysByCategory[_selectedChipIndex];

                      if (journeys.isEmpty) {
                        return const Center(
                          child: Text(
                            "No journeys available for this category.",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      return PageView.builder(
                        controller: PageController(viewportFraction: constraints.maxWidth > 400 ? 0.8 : 0.9),
                        itemCount: journeys.length,
                        itemBuilder: (context, pageViewIndex) {
                          final journey = journeys[pageViewIndex];
                          final String journeyId = journey.stringId;
                          final bool isFav = _currentUserFavorites.contains(journeyId);
                          final String formattedDate =
                            "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(File(journey.mainImagePath)),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                     print('Error loading image: ${journey.mainImagePath} $exception');
                                  },
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                journey.country,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                journey.city,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'inter',
                                            fontSize: 16,
                                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
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
                                                  journeyId: journey.id!,
                                                  username: widget.username,
                                                ),
                                              ),
                                            ).then((_){
                                              if(mounted) {
                                                _loadInitialFavorites();
                                              }
                                            });
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
                                          color: isFav ? Colors.red : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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


class JourneyDetailScreen extends StatefulWidget {
  
  final int journeyId; 
  final String username;

  const JourneyDetailScreen({
    super.key,
    required this.journeyId, 
    required this.username,
  });

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  Journey? _journey; 
  bool _isLoading = true;
  Map<String, bool> _additionalImageLikes = {};
  bool _isCurrentJourneyFavorite = false; 

  @override
  void initState() {
    super.initState();
    favoritesService.addListener(_onFavoritesChanged);
    _loadJourneyDetails();
  }

  
  Future<void> _loadJourneyDetails() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  final dbHelper = DatabaseHelper();
  
  final journeyFromDb = await dbHelper.getJourneyById(widget.journeyId, widget.username);
    if (mounted) {
      setState(() {
        _journey = journeyFromDb;
        if (_journey != null) {
          
          favoritesService.isFavorite(_journey!.stringId, widget.username).then((isFav) {
            if (mounted) {
              setState(() {
                _isCurrentJourneyFavorite = isFav;
              });
            }
          });
          _additionalImageLikes = {
            for (var path in _journey!.additionalImagePaths) path: false
          };
        }
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  void _onFavoritesChanged() {
    if (mounted && _journey != null) {
      favoritesService.isFavorite(_journey!.stringId, widget.username).then((isFav) {
        if (mounted) {
          setState(() {
            _isCurrentJourneyFavorite = isFav;
          });
        }
      });
    }
    if (mounted) setState(() {}); 
  }
  
  void _toggleAdditionalImageLike(String imagePath) {
    if (mounted && _journey != null) {
      setState(() {
        _additionalImageLikes[imagePath] = !(_additionalImageLikes[imagePath] ?? false);
      });
    }
  }

  
  void _toggleMainFavorite() {
    if (_journey != null) {
      favoritesService.toggleFavorite(_journey!.stringId, widget.username);
    }
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_journey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Journey not found.")),
      );
    }

    
    final bool isMainFavorite = _isCurrentJourneyFavorite;
    final String formattedDate =
        "${DateFormat('dd.MM.yy').format(_journey!.startDate)} - ${DateFormat('dd.MM.yy').format(_journey!.endDate)}";

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
                    child: Image.file( 
                      File(_journey!.mainImagePath),
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey,
                        child: Center(
                            child: Text(
                                'Image not found: ${_journey!.mainImagePath}')),
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
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 20),
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
                    color: isMainFavorite ? Colors.red : Colors.black,
                    size: 24),
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
              padding: const EdgeInsets.only(
                  top: 30, left: 25, right: 25, bottom: 20),
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
                                _journey!.city,
                                style: const TextStyle(
                                  fontFamily: 'Inter-Bold',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                _journey!.country,
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
                            formattedDate,
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
                    Text( 
                      _journey!.description.isNotEmpty
                          ? _journey!.description
                          : "No description available.",
                      style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                      textAlign: TextAlign.justify, 
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Yours memory",
                          style: TextStyle(
                            fontFamily: 'Inter-Bold',
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _journey!.additionalImagePaths.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                                child: Text("No additional memories added.",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey))),
                          )
                        : SizedBox(
                            height: 180, 
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _journey!.additionalImagePaths.length,
                              itemBuilder: (context, index) {
                                final imagePath = _journey!.additionalImagePaths[index];
                                final isLiked = _additionalImageLikes[imagePath] ?? false;
                                return Container(
                                  width: 240, 
                                  margin: const EdgeInsets.only(right: 15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        child: GestureDetector(
                                          onTap: () => _toggleAdditionalImageLike(imagePath),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.white70, 
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked ? Colors.red : Colors.black,
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


class GalleryScreen extends StatefulWidget {
  final String username;
  const GalleryScreen({super.key, required this.username});
  

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _selectedIndex = 1;
  List<Journey> _allJourneysForGallery = []; 
  bool _isLoading = true; 
  Set<String> _currentUserFavorites = {};
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged); 
    _loadInitialFavorites();
    favoritesService.addListener(_onFavoritesChanged);
    _loadJourneysForGallery(); 
  }
  
  void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged); 
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  Future<void> _loadInitialFavorites() async {
    if (!mounted) return;
    _currentUserFavorites = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    if (mounted) setState(() {});
  }

  Future<void> _loadJourneysForGallery() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  final dbHelper = DatabaseHelper();

  
  final journeysFromDb = await dbHelper.getJourneysForUser(widget.username);

  if (mounted) { 
    setState(() {
      _allJourneysForGallery = journeysFromDb;
      _isLoading = false;
    });
  }
}

  @override
  
  void dispose1s() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  void _onFavoritesChanged() {
    _loadInitialFavorites();
  }

  
  void _toggleFavoriteStatus(String journeyId) {
    favoritesService.toggleFavorite(journeyId, widget.username);
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) {
      if (index == 1 && mounted) {
         _loadJourneysForGallery();
         _loadInitialFavorites();
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
        nextPage = HomeScreen(username: widget.username);
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username);
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username);
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username);
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
                        "Gallery",
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
      MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)),
    );
  },
  child: CircleAvatar( 
    radius: 34,
    backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
        ? FileImage(File(_profileData!.imagePath!))
        : const AssetImage("assets/profile1.png") as ImageProvider,
    onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
        ? (exception, stackTrace) {
            print('Error loading profile image in HomeScreen: ${_profileData!.imagePath} $exception');
            
          }
        : null,
  ),
),
                ],
                
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allJourneysForGallery.isEmpty
                      ? const Center(
                          child: Text("No journeys in gallery yet.",
                              style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _allJourneysForGallery.length,
                          itemBuilder: (context, index) {
                            final journey = _allJourneysForGallery[index];
                            final String journeyId = journey.stringId;
                            
                            final bool isFav = _currentUserFavorites.contains(journeyId);
                            final String formattedDate =
                                "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JourneyDetailScreen(
                                        
                                        journeyId: journey.id!, 
                                        username: widget.username,
                                      ),
                                    ),
                                  ).then((_) { 
                                    if (mounted) {
                                      _loadInitialFavorites();
                                    }
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file( 
                                        File(journey.mainImagePath),
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 200,
                                          color: Colors.grey[300],
                                          child: const Center(
                                              child: Text('Image N/A')),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                journey.city,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                journey.country,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'Inter',
                                                    color: Colors.black54),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _toggleFavoriteStatus(
                                                    journeyId);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  isFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 22,
                                                  color: isFav
                                                      ? Colors.red
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
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

class FavouritePage extends StatefulWidget {
  final String username;
  const FavouritePage({super.key, required this.username});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  int _selectedIndex = 2;
  List<Journey> _favoriteJourneys = []; 
  bool _isLoading = true;
  Timer? _timer;
  int _currentBigImageIndex = 0; 
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 2;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged); 
    favoritesService.addListener(_loadFavoriteJourneys); 
    _loadFavoriteJourneys(); 
  }

   void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }


  Future<void> _loadFavoriteJourneys() async {
  if (!mounted) return;
  setState(() => _isLoading = true); 

  final dbHelper = DatabaseHelper();
  
  
  final List<Journey> userSpecificJourneys = await dbHelper.getJourneysForUser(widget.username);
  
  if (mounted) {
    
    final Set<String> favIds = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    
    setState(() {
      
      _favoriteJourneys = userSpecificJourneys.where((journey) => favIds.contains(journey.stringId)).toList();
      _isLoading = false;
      _currentBigImageIndex = 0;
      if (_favoriteJourneys.isNotEmpty) {
        _startImageTimer();
      } else {
        _timer?.cancel();
      }
    });
  }
}
  
  void _startImageTimer() {
    _timer?.cancel(); 
    if (_favoriteJourneys.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
        if (mounted && _favoriteJourneys.isNotEmpty) {
          setState(() {
            _currentBigImageIndex = (_currentBigImageIndex + 1) % _favoriteJourneys.length;
          });
        } else {
          timer.cancel(); 
        }
      });
    }
  }


  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged); 
    favoritesService.removeListener(_loadFavoriteJourneys);
    _timer?.cancel();
    super.dispose();
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) {
      if (index == 2 && mounted) { 
          _loadFavoriteJourneys(); 
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
        nextPage = HomeScreen(username: widget.username);
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username);
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username);
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username);
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
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(username: widget.username)),
                      );
                    },
                    child: CircleAvatar( 
              radius: 34,
              backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? FileImage(File(_profileData!.imagePath!))
                  : const AssetImage("assets/profile1.png") as ImageProvider,
              onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? (exception, stackTrace) {
                      print('Error loading profile image in GalleryScreen: ${_profileData!.imagePath} $exception');
                    }
                  : null,
            ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : _favoriteJourneys.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Container( 
                            width: 410,
                            height: 388,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[200], 
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                                child: Text(
                              "No favorite journeys yet.",
                              style: TextStyle(fontSize: 18, color: Colors.black54),
                            )),
                          ),
                        ),
                      )
                    : GestureDetector( 
                        onTap: () {
                           if (_favoriteJourneys.isNotEmpty) {
                             final journey = _favoriteJourneys[_currentBigImageIndex];
                             final String formattedDate = "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => JourneyDetailScreen(
                                   journeyId: journey.id!,
                                   username: widget.username,
                                 ),
                               ),
                             ).then((_) {
                                if (mounted) {
                                  _loadFavoriteJourneys(); 
                                }
                              });
                           }
                        },
                        child: Container(
                          width: 410,
                          height: 388,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: FileImage(File(_favoriteJourneys[_currentBigImageIndex].mainImagePath)),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                 print('Error loading big favorite image: ${_favoriteJourneys[_currentBigImageIndex].mainImagePath} $exception');
                              }
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column( 
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _favoriteJourneys[_currentBigImageIndex].city,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black87)]
                                    ),
                                  ),
                                  Text(
                                    _favoriteJourneys[_currentBigImageIndex].country,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                       shadows: [Shadow(blurRadius: 2.0, color: Colors.black87)]
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  
                                  GestureDetector(
                                    onTap: () {
                                      if (_favoriteJourneys.isNotEmpty) {
                                        favoritesService.toggleFavorite(
                                          _favoriteJourneys[_currentBigImageIndex].stringId,
                                          widget.username
                                        );
                                        
                                      }
                                    },
                                    child: const Icon(Icons.favorite, color: Colors.white, size: 30)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const SizedBox.shrink() 
                  : _favoriteJourneys.isEmpty
                      ? const Center(child: Text("")) 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, 
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1, 
                            ),
                            itemCount: _favoriteJourneys.length,
                            itemBuilder: (context, index) {
                              final journey = _favoriteJourneys[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JourneyDetailScreen(
                                        journeyId: journey.id!,
                                        username: widget.username,
                                      ),
                                    ),
                                  ).then((_){
                                     if (mounted) {
                                      _loadFavoriteJourneys();
                                    }
                                  });
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        File(journey.mainImagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          Container(color: Colors.grey[300], child: Icon(Icons.image_not_supported, color: Colors.grey[500])),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Icon(Icons.favorite,
                                          color: Colors.white70, size: 16),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      right: 6,
                                      child: Text(
                                        journey.city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          shadows: [Shadow(blurRadius: 1.0, color: Colors.black)]
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
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


class StatisticPage extends StatefulWidget {
  final String username;
  const StatisticPage({super.key, required this.username});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedIndex = 3;
  
  List<Journey> _allJourneysForStats = [];
  bool _isLoadingStats = true;

  Map<String, int> _calculatedTripStatusData = {};
  List<Map<String, dynamic>> _calculatedMostVisitedCountries = [];
  List<Map<String, dynamic>> _calculatedActivityPerYear = [];
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 3;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged);
    _loadJourneysForStats();
  }

  void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }

  Future<void> _loadJourneysForStats() async {
  if (!mounted) return;
  setState(() => _isLoadingStats = true);
  final dbHelper = DatabaseHelper();

  
  _allJourneysForStats = await dbHelper.getJourneysForUser(widget.username);
  _calculateStatistics(); 
  
  if (mounted) { 
    setState(() => _isLoadingStats = false);
  }
}

  void _calculateStatistics() {
    _calculatedTripStatusData = {
      'Ongoing': 0, 'Draft': 0, 'Past': 0, 'Upcoming': 0,
    };
    for (var journey in _allJourneysForStats) {
      final status = journey.status;
      if (_calculatedTripStatusData.containsKey(status)) {
        _calculatedTripStatusData[status] = _calculatedTripStatusData[status]! + 1;
      }
    }

    Map<String, int> countryVisits = {};
    for (var journey in _allJourneysForStats) {
      final country = journey.country;
      countryVisits[country] = (countryVisits[country] ?? 0) + 1;
    }
    var sortedCountries = countryVisits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final List<Color> countryColors = [ 
      Colors.red.shade400, Colors.blue.shade400, Colors.green.shade400, 
      Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400
    ];
    _calculatedMostVisitedCountries = sortedCountries.take(5).map((entry) {
      return {'name': entry.key, 'visits': entry.value, 'color': countryColors[(_calculatedMostVisitedCountries.length % countryColors.length)]};
    }).toList();


    Map<int, int> activityCountPerYear = {};
    for (var journey in _allJourneysForStats) {
      final year = journey.startDate.year;
      activityCountPerYear[year] = (activityCountPerYear[year] ?? 0) + 1;
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
      if (index == 3 && mounted) { 
          _loadJourneysForStats(); 
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
        nextPage = HomeScreen(username: widget.username);
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username);
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username);
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username);
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
        child: _isLoadingStats
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                        MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)),
                      );
                    },
                    child: CircleAvatar(
              radius: 34,
              backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? FileImage(File(_profileData!.imagePath!))
                  : const AssetImage("assets/profile1.png") as ImageProvider,
              onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? (exception, stackTrace) {
                      print('Error loading profile image in GalleryScreen: ${_profileData!.imagePath} $exception');
                    }
                  : null,
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
                              
                              final int numberOfBars = _calculatedActivityPerYear.length;
                              final double totalHorizontalPaddingInCard = 40; 
                              final double spacingBetweenBars = 15.0;
                              final double chartContainerWidth = screenWidth - 40 - totalHorizontalPaddingInCard; 
                              final double totalSpacing = (numberOfBars - 1) * spacingBetweenBars;
                              double barWidth = (chartContainerWidth - totalSpacing) / max(1, numberOfBars); 
                              barWidth = max(10, barWidth * 0.8); 

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
                                    barWidth
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

 Widget _buildActivityBar(BuildContext context, String year, double activity, double maxActivity, Color color, double availableHeight, double barWidth) {
    final barHeightPercentage = maxActivity == 0 ? 0.0 : (activity / maxActivity);
    final barHeight = barHeightPercentage * (availableHeight * 0.9);

    return Column(
      mainAxisSize: MainAxisSize.min, 
      mainAxisAlignment: MainAxisAlignment.end, 
      children: [
        Container(
          width: barWidth, 
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

class ProfileScreen extends StatefulWidget {
  final String username; 

  const ProfileScreen({super.key, required this.username}); 

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _profile = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
  if (_profile == null || userProfileService.currentUserProfile == null || userProfileService._currentLoginIdentifier != widget.username) {
    print("ProfileScreen: _profile is null or mismatched. Attempting to load for ${widget.username}");
    await userProfileService.loadProfileForExistingUser(widget.username);

    if (!mounted) return;

    if (userProfileService.currentUserProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data not available. Please try again.')),
      );
      return;
    }
    setState(() {
      _profile = userProfileService.currentUserProfile;
    });
  }
  if (_profile == null) {
    print("ProfileScreen: _profile is still null after attempting load. Cannot navigate to edit.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Profile data is missing.')),
    );
    return;
  }
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditProfileScreen(initialProfile: _profile!),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final String displayName = _profile?.username ?? widget.username;
    final String displayEmail = _profile?.email ?? "${widget.username.toLowerCase().replaceAll(' ', '_')}@example.com";
    final String? displayImagePath = _profile?.imagePath;

    ImageProvider<Object>? avatarImageProvider;
    if (displayImagePath != null && displayImagePath.isNotEmpty) {
      avatarImageProvider = FileImage(File(displayImagePath));
    } else {
      avatarImageProvider = const AssetImage("assets/profile1.png");
    }

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
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading profile image on ProfileScreen: $displayImagePath $exception');
              },
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              displayEmail,
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.black54.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToEditProfile, 
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
                        if(mounted) setState(() => _notificationsEnabled = value);
                      },
                      activeColor: Colors.green,
                    ),
                    onTap: () {
                       if(mounted) setState(() => _notificationsEnabled = !_notificationsEnabled);
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
                    onTap: () async {
                       
                       final String? currentLoginId = userProfileService._currentLoginIdentifier;

                       
                       await userProfileService.clearCurrentProfileData();
                       
                       
                       if (currentLoginId != null) {
                         await favoritesService.clearFavoritesForUser(currentLoginId);
                       }
                       
                       if (mounted) {
                         Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const SplashScreen()),
                          (Route<dynamic> route) => false,
                        );
                       }
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

class EditProfileScreen extends StatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  XFile? _newImageFile;
  String? _imagePathForDisplay;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.username);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _imagePathForDisplay = widget.initialProfile.imagePath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null && mounted) {
      setState(() {
        _newImageFile = pickedFile;
        _imagePathForDisplay = pickedFile.path; 
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) setState(() => _isLoading = true);

      String? finalImagePath = widget.initialProfile.imagePath;

      if (_newImageFile != null) {
        
        finalImagePath = await userProfileService.saveProfileImage(_newImageFile!);
      }

      final updatedProfile = UserProfile(
        username: _nameController.text,
        email: _emailController.text,
        imagePath: finalImagePath,
      );

      await userProfileService.updateProfile(updatedProfile);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? backgroundImage;
    if (_imagePathForDisplay != null) {
      backgroundImage = FileImage(File(_imagePathForDisplay!));
    } else {
      backgroundImage = const AssetImage("assets/profile1.png");
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFA8D5BA),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: backgroundImage,
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Error loading image for avatar: $exception");
                        },
                        child: _imagePathForDisplay == null && _newImageFile == null
                            ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceDialog,
                      child: const Text("Change Photo", style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A261),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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
      if (value > 0) { 
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
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      if (oldDelegate.data.length != data.length) return true;
      for (var key in data.keys) {
        if (oldDelegate.data[key] != data[key]) return true;
      }
      return false;
    }
    return true;
  }
}



class FavoritesService extends ChangeNotifier {
  final Map<String, Set<String>> _userFavorites = {};

  Set<String> _getFavoritesSetForUser(String username) {
    if (!_userFavorites.containsKey(username)) {
      _userFavorites[username] = {};
    }
    return _userFavorites[username]!;
  }
  Future<bool> isFavorite(String journeyId, String username) async {
    
    final userFavs = _getFavoritesSetForUser(username);
    return userFavs.contains(journeyId);
  }

  Future<void> toggleFavorite(String journeyId, String username) async {
  
    final userFavs = _getFavoritesSetForUser(username);

    if (userFavs.contains(journeyId)) {
      userFavs.remove(journeyId);
    } else {
      userFavs.add(journeyId);
    }
    
    
    notifyListeners();
  }
  Future<Set<String>> getFavoriteJourneyIdsForUser(String username) async {
    return _getFavoritesSetForUser(username);
  }

  Future<void> clearFavoritesForUser(String username) async {
    if (_userFavorites.containsKey(username)) {
      _userFavorites.remove(username);
      notifyListeners();
    }
  }

  Future<void> clearAllFavoritesData() async {
      _userFavorites.clear();
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
                        width: 70, 
                        height: 30,
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