import 'package:flutter/material.dart';
import 'package:front_end_app/services/auth_service.dart';
import 'package:front_end_app/screens/login_screen.dart';
// (Import các màn hình của bạn)
import 'package:front_end_app/screens/dat_ban_screen.dart'; // (Tự tạo file này)
import 'package:front_end_app/screens/history_screen.dart'; // (Tí nữa tui tạo)


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String _hoTen = "Đang tải...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String? hoTen = await _authService.getUserNameFromToken();
    if (hoTen != null) {
      setState(() {
        _hoTen = hoTen;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. THANH APPBAR (ĐÃ SỬA)
      appBar: AppBar(
        title: Text("Trang chủ"),
        backgroundColor: Colors.blue, // Thêm màu
      ),

      // 2. THANH MENU KÉO (DRAWER) (MỚI)
      drawer: _buildDrawer(),

      // 3. GIAO DIỆN "ĐẸP" (MỚI)
      body: Container(
        // Dùng Gradient (màu chuyển) cho đẹp
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text chào mừng
                Text(
                  "Xin chào,",
                  style: TextStyle(fontSize: 28, color: Colors.grey[700]),
                ),
                Text(
                  _hoTen,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 60),

                // 2 NÚT CHỨC NĂNG
                _buildFunctionCard(
                  context,
                  icon: Icons.calendar_today,
                  title: "Đặt Bàn Ngay",
                  subtitle: "Tìm và đặt bàn nhanh chóng",
                  onTap: () {
                    // TODO: Đổi DatBanScreen() thành tên file của bạn
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DatBanScreen()));
                  },
                ),
                SizedBox(height: 20),
                _buildFunctionCard(
                  context,
                  icon: Icons.history,
                  title: "Lịch Sử Đặt Bàn",
                  subtitle: "Xem lại hoặc hủy đặt bàn",
                  onTap: () {
                    // Chuyển sang màn hình Lịch sử (tí nữa tui code)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER CHO DRAWER (MENU KÉO) ---
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Phần Header của Drawer
          UserAccountsDrawerHeader(
            accountName: Text(
              _hoTen,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("Khách hàng thành viên"), // (Lấy SĐT/Email nếu muốn)
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _hoTen.isNotEmpty ? _hoTen[0].toUpperCase() : "A", // Chữ cái đầu
                style: TextStyle(fontSize: 40.0, color: Colors.blue[800]),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),

          // Các mục menu
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context); // Đóng Drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Thông tin cá nhân'),
            onTap: () {
              // TODO: Tạo trang ProfileScreen
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _logout, // Gọi hàm đăng xuất
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER CHO CÁI NÚT "ĐẸP" ---
  Widget _buildFunctionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40.0, color: Colors.blue[700]),
            SizedBox(width: 20.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}