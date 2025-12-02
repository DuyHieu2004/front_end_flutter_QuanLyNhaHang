import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // --- HÀM NÀY ĐÃ SỬA LẠI ĐƯỜNG DẪN ẢNH (theo code của bạn) ---
  List<Widget> _buildPages() {
    return [
      _buildPage(
        imagePath: 'assets/images/splash2.jpg',
        title: 'Tìm Kiếm Nhanh Chóng',
        description: 'Dễ dàng tìm kiếm và đặt bàn nhà hàng yêu thích của bạn chỉ trong vài giây.',
      ),
      _buildPage(
        imagePath: 'assets/images/splash3.jpg',
        title: 'Tích Điểm & Ưu Đãi',
        description: 'Tích lũy điểm thưởng sau mỗi lần đặt bàn và đổi lấy các voucher giảm giá hấp dẫn.',
      ),
      _buildPage(
        imagePath: 'assets/images/splash4.jpg',
        title: 'Không Lo Chờ Đợi',
        description: 'Với tính năng hàng chờ ảo, bạn sẽ được thông báo ngay khi có bàn trống.',
      ),
    ];
  }

  // --- HÀM NÀY ĐÃ ĐƯỢC "TÂN TRANG" LẠI CHO "ĐẸP" ---
  Widget _buildPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    // Dùng Column (Ảnh trên, Chữ dưới)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- PHẦN HÌNH ẢNH (Chiếm 60%) ---
        Expanded(
          flex: 3, // Chiếm 3/5 không gian
          child: Container(
            margin: const EdgeInsets.only(
                top: 30.0,
                left: 20.0,
                right: 20.0,
                bottom: 10.0
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0), // Bo góc ảnh
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover, // Phủ đầy container
                width: double.infinity,
              ),
            ),
          ),
        ),

        // --- PHẦN TEXT (Chiếm 40%) ---
        Expanded(
          flex: 2, // Chiếm 2/5 không gian
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26, // Chữ to, rõ ràng
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[850], // Màu chữ đậm
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4, // Giãn dòng cho dễ đọc
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // --- HẾT PHẦN "TÂN TRANG" ---


  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < 3; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  _currentPage == 2 ? '' : 'Bỏ qua',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _buildPages(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == 2) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == 2 ? 'Bắt đầu' : 'Tiếp',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}