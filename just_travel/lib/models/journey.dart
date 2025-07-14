import 'dart:convert';

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
