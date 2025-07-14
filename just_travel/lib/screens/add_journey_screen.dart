import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io'; 
import 'package:intl/intl.dart'; 
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../services/database_helper.dart';
import '../models/journey.dart';

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
