import 'dart:async';
import 'package:flutter/material.dart';

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