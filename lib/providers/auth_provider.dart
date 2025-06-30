import 'package:flutter/material.dart';
import 'package:flutter_task_of_apicalling_and_data_management/models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _token = await _storageService.getToken();
    if (_token != null) {
      await getUserProfile();
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      _user = response.user;
      _token = response.token;
      await _storageService.saveToken(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> getUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _apiService.getUserProfile(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
