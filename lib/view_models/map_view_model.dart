import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapViewModel extends ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<void> fetchUserLocation() async {
    try {
      print("Fetching user location...");
      _currentPosition = await Geolocator.getCurrentPosition();
      print("Location fetched: $_currentPosition");
      notifyListeners();
    } catch (e) {
      print("Error fetching location: $e");
    }
  }
}