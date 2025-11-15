import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'dart:async'; // <--- 1. IMPORT DART:ASYNC ĐỂ DÙNG TIMER

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- PHẦN LOGIC (Y CHANG CŨ, KHÔNG SỬA) ---
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _hoTenController = TextEditingController();

  // --- 2. THÊM CÁC BIẾN ĐỂ QUẢN LÝ TIMER ---
  Timer? _timer;
  int _countdownSeconds = 30; // Thời gian đếm ngược (giây)
  // Biến này dùng để theo dõi state của Provider,
  // giúp ta biết khi nào state thay đổi để bắt đầu timer
  AuthStep _currentStepInState = AuthStep.Initial;

  // --- 3. VIẾT HÀM ĐIỀU KHIỂN TIMER ---
  void startTimer() {
    stopTimer(); // Hủy timer cũ nếu có
    _countdownSeconds = 30; // Reset thời gian
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          // Kiểm tra xem widget còn tồn tại không
          setState(() {
            _countdownSeconds--;
          });
        }
      } else {
        stopTimer(); // Dừng timer khi về 0
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // --- 4. VIẾT HÀM GỬI LẠI OTP ---
  void _resendOtp(BuildContext context) {
    // Chỉ gửi lại khi timer đã về 0
    if (_countdownSeconds == 0) {
      startTimer(); // Bắt đầu lại timer
      // Gọi lại hàm checkUser (cũng là hàm gửi OTP)
      Provider.of<AuthProvider>(context, listen: false)
          .checkUser(_identifierController.text);
    }
  }

  // --- 5. CẬP NHẬT CÁC HÀM CŨ ---
  void _goBackToInitial(BuildContext context) {
    stopTimer(); // <-- Dừng timer khi quay lại
    Provider.of<AuthProvider>(context, listen: false).goBackToInitial();
    _otpController.clear();
    _hoTenController.clear();
  }

  void _onSubmit(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) return;

    switch (authProvider.currentStep) {
      case AuthStep.Initial:
      // Hàm checkUser SẼ KÍCH HOẠT timer (xem ở hàm build)
        authProvider.checkUser(_identifierController.text);
        break;
      case AuthStep.EnterOtpLogin:
        bool success = await authProvider.login(
          _identifierController.text,
          _otpController.text,
        );
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
        break;
      case AuthStep.EnterOtpRegister:
        bool success = await authProvider.register(
          _identifierController.text,
          _hoTenController.text,
          _otpController.text,
        );
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    stopTimer(); // <-- Hủy timer khi widget bị xóa
    _identifierController.dispose();
    _otpController.dispose();
    _hoTenController.dispose();
    super.dispose();
  }

  // --- 6. HÀM BUILD ĐÃ ĐƯỢC CẬP NHẬT ---
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // --- LOGIC TỰ ĐỘNG CHẠY TIMER ---
    // So sánh state của provider với state ta lưu
    if (authProvider.currentStep != _currentStepInState) {
      // Nếu state VỪA MỚI chuyển sang màn hình OTP
      if (authProvider.currentStep == AuthStep.EnterOtpLogin ||
          authProvider.currentStep == AuthStep.EnterOtpRegister) {
        // Chạy timer ngay lập tức
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startTimer();
        });
      }
      // Nếu state VỪA MỚI quay về màn hình ban đầu
      if (authProvider.currentStep == AuthStep.Initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopTimer(); // Dừng timer
        });
      }
      // Cập nhật state ta lưu để lần build sau không bị lặp
      _currentStepInState = authProvider.currentStep;
    }
    // --- HẾT LOGIC TIMER ---

    return Scaffold(
      body: Stack(
        children: [
          // LỚP 1: ẢNH NỀN
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),

          // LỚP 2: LÀM MỜ
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // LỚP 3: NÚT QUAY LẠI
          if (authProvider.currentStep != AuthStep.Initial)
            Positioned(
              top: 40.0,
              left: 10.0,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _goBackToInitial(context),
                ),
              ),
            ),

          // LỚP 4: NỘI DUNG CHÍNH
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. LOGO
                  SizedBox(height: 80),
                  Image.asset(
                    'assets/images/logo.jpg',
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _buildTitle(authProvider.currentStep),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),

                  // 2. KHỐI FORM
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        if (authProvider.currentStep == AuthStep.Initial)
                          _buildInitialStep()
                        else
                          _buildOtpStep(authProvider.currentStep), // <-- ĐÃ SỬA BÊN TRONG

                        if (authProvider.currentStep == AuthStep.EnterOtpRegister)
                          _buildRegisterStep(),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // 3. NÚT SUBMIT
                  if (authProvider.isLoading)
                    CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Màu nút
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        onPressed: () => _onSubmit(context),
                        child: Text(
                          _buildButtonText(authProvider.currentStep),
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // 4. THÔNG BÁO LỖI
                  if (authProvider.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        authProvider.errorMessage,
                        style: TextStyle(
                          color: Colors.yellow[300], // Màu vàng cho dễ thấy
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC HÀM BUILD WIDGET (ĐÃ SỬA LẠI) ---

  Widget _buildInitialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nhập SĐT hoặc Email để tiếp tục",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8), // <-- Sửa màu
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        _buildStyledTextField(
          controller: _identifierController,
          labelText: "SĐT hoặc Email",
          icon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // --- 7. HÀM NÀY ĐƯỢC SỬA NHIỀU NHẤT ---
  Widget _buildOtpStep(AuthStep currentStep) {
    // Biến kiểm tra xem timer đang chạy hay đã hết
    final bool isTimerRunning = _countdownSeconds > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentStep == AuthStep.EnterOtpLogin
              ? "Bạn đã có tài khoản. Mã OTP đã được gửi đến:"
              : "Đây là tài khoản mới. Mã OTP đã được gửi đến:",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8), // <-- Sửa màu
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _identifierController.text,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), // <-- Sửa màu
        ),
        SizedBox(height: 8),
        Text(
          "Vui lòng kiểm tra Email (cả hòm thư Spam) hoặc Console Back-end (nếu là SĐT).",
          style: TextStyle(
              color: Colors.white.withOpacity(0.6), // <-- Sửa màu
              fontStyle: FontStyle.italic,
              fontSize: 12),
        ),
        SizedBox(height: 20),
        _buildStyledTextField(
          controller: _otpController,
          labelText: "Nhập OTP",
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
        ),

        // --- 8. WIDGET MỚI: TIMER VÀ NÚT GỬI LẠI ---
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Đồng hồ đếm ngược
            Text(
              isTimerRunning
                  ? "Gửi lại sau: 00:${_countdownSeconds.toString().padLeft(2, '0')}"
                  : "Bạn chưa nhận được mã?",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),

            // Nút Gửi lại mã
            TextButton(
              // Khi timer đang chạy (isTimerRunning = true), onPressed sẽ là null
              // -> Nút tự động bị vô hiệu hóa (mờ đi)
              onPressed: isTimerRunning ? null : () => _resendOtp(context),
              style: TextButton.styleFrom(
                // Màu chữ khi bị vô hiệu hóa
                disabledForegroundColor: Colors.white.withOpacity(0.4),
              ),
              child: Text(
                "Gửi lại mã",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // Khi được phép nhấn, màu sẽ sáng hơn
                  color: isTimerRunning
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white,
                ),
              ),
            ),
          ],
        )
        // --- HẾT PHẦN WIDGET MỚI ---
      ],
    );
  }

  Widget _buildRegisterStep() {
    return Column(
      children: [
        SizedBox(height: 16),
        _buildStyledTextField(
          controller: _hoTenController,
          labelText: "Nhập Họ Tên",
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  // Sửa lại hàm này cho đẹp hơn
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white), // Chữ người dùng gõ
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)), // Chữ gợi ý
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)), // Icon
        filled: true,
        fillColor: Colors.white.withOpacity(0.2), // Nền
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // Viền
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.white, width: 2.0), // Viền khi focus
        ),
      ),
    );
  }

  // --- CÁC HÀM HELPER KHÁC (Y CHANG CŨ) ---
  String _buildTitle(AuthStep currentStep) {
    switch (currentStep) {
      case AuthStep.Initial:
        return "Chào mừng!";
      case AuthStep.EnterOtpLogin:
        return "Đăng nhập";
      case AuthStep.EnterOtpRegister:
        return "Đăng ký";
    }
  }

  String _buildButtonText(AuthStep currentStep) {
    switch (currentStep) {
      case AuthStep.Initial:
        return "Tiếp tục";
      case AuthStep.EnterOtpLogin:
        return "Đăng nhập";
      case AuthStep.EnterOtpRegister:
        return "Hoàn tất Đăng ký";
    }
  }
}