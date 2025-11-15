import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStep {
  Initial,
  EnterOtpLogin,
  EnterOtpRegister
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStep _currentStep = AuthStep.Initial;
  bool _isLoading = false;
  String _errorMessage = "";

  AuthStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> checkUser(String identifier) async {
    if (identifier.isEmpty) {
      _errorMessage = "Vui lòng nhập SĐT hoặc Email";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      bool userExists = await _authService.checkUserExists(identifier);

      if (userExists) {
        _currentStep = AuthStep.EnterOtpLogin;
      } else {
        _currentStep = AuthStep.EnterOtpRegister;
      }
    } catch (e, stackTrace) {

      _errorMessage = "Đã xảy ra lỗi: ${e.toString()}";
      print(_errorMessage);

      // ----- THÊM DÒNG NÀY ĐỂ DEBUG -----
      print("===== LỖI CHI TIẾT KHI CHECK USER =====");
      print(e); // In ra lỗi
      print(stackTrace);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String identifier, String otp) async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      bool success = await _authService.login(identifier, otp);

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "OTP không chính xác!";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Lỗi đăng nhập: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String identifier, String hoTen, String otp) async {
    if (hoTen.isEmpty) {
      _errorMessage = "Vui lòng nhập Họ Tên";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      bool success = await _authService.register(identifier, hoTen, otp);

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "OTP không chính xác!";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Lỗi đăng ký: ${e.toString()}";
      print(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void goBackToInitial() {
    _currentStep = AuthStep.Initial;
    _errorMessage = "";
    notifyListeners();
  }
}