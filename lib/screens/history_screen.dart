import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Đảm bảo đã thêm package này
import 'package:front_end_app/services/auth_service.dart';
import 'package:front_end_app/utils/QuickAlert.dart';
import 'booking_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  
  // --- COLOR PALETTE (ĐỒNG BỘ MENU SCREEN) ---
  final Color _wineRed = const Color(0xFF800020);
  final Color _lightWine = const Color(0xFFA52A2A);
  final Color _bgWhite = const Color(0xFFFAFAFA);
  
  // Tra cứu bằng số điện thoại
  final _phoneController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _searchResult;
  List<dynamic> _searchBookings = [];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _searchByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      QuickAlertService.showAlertFailure(context, "Vui lòng nhập số điện thoại");
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchBookings = [];
    });

    try {
      final result = await _authService.getHistoryByPhone(phone);
      setState(() {
        _searchResult = result;
        _searchBookings = result['bookings'] ?? [];
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResult = null;
        _searchBookings = [];
      });
      QuickAlertService.showAlertFailure(
        context,
        e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showBookingDetail(String maDonHang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(maDonHang: maDonHang),
      ),
    );
  }

  void _cancelBooking(String maDonHang) async {
    QuickAlertService.showAlertConfirm(
      context,
      "Bạn có chắc chắn muốn hủy đơn đặt bàn này không?",
      () async {
        QuickAlertService.showAlertLoading(context, "Đang xử lý hủy...");
        try {
          await _authService.cancelBooking(maDonHang);
          Navigator.of(context, rootNavigator: true).pop();
          QuickAlertService.showAlertSuccess(context, "Hủy đặt bàn thành công!");
          
          if (_searchResult != null && _phoneController.text.isNotEmpty) {
            _searchByPhone();
          }
        } catch (e) {
          Navigator.of(context, rootNavigator: true).pop();
          String errorMsg = e.toString().replaceAll("Exception: ", "");
          QuickAlertService.showAlertFailure(context, errorMsg);
        }
      },
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "LỊCH SỬ ĐẶT BÀN",
          style: TextStyle(
            color: _wineRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: _wineRed),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchSection(),
            const SizedBox(height: 24),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        // Banner Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_wineRed, _lightWine],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _wineRed.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tra cứu lịch sử",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Nhập số điện thoại để xem lại các đơn đặt bàn của bạn",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 24),

        // Search Input Box
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Nhập số điện thoại...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.phone_iphone, color: _wineRed),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchByPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wineRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_searchResult == null && !_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.manage_search, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Kết quả tìm kiếm sẽ hiển thị tại đây",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searchResult != null && _searchResult!['message'] != null)
           Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _searchResult!['message'],
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
           ),

        // Customer Info Card
        if (_searchResult != null && _searchResult!['customer'] != null)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wineRed.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _wineRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: _wineRed, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchResult!['customer']['hoTen'] ?? "Khách hàng",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchResult!['customer']['soDienThoai'] ?? "",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(),

        // Bookings List
        if (_searchBookings.isEmpty && _searchResult != null)
           Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "Khách hàng chưa có lịch sử đặt bàn",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchBookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(_searchBookings[index], index);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(dynamic booking, int index) {
    // Logic Date Parsing (Giữ nguyên logic cũ nhưng wrap lại cho gọn)
    DateTime thoiGianBatDau = DateTime.now();
    try {
      if (booking['thoiGianBatDau'] != null) {
        thoiGianBatDau = DateTime.parse(booking['thoiGianBatDau']);
      } else if (booking['thoiGianAn'] != null) {
        thoiGianBatDau = DateTime.parse(booking['thoiGianAn']);
      } else {
        thoiGianBatDau = DateTime.parse(booking['thoiGianDatHang'] ?? DateTime.now().toIso8601String());
      }
    } catch (_) {}

    String formattedTime = DateFormat('HH:mm - dd/MM/yyyy').format(thoiGianBatDau);
    
    // Status Logic
    String maTrangThai = booking['maTrangThai'] ?? "";
    String tenTrangThai = booking['trangThai'] ?? "Không rõ";
    bool daHuy = booking['daHuy'] ?? false;
    bool hoanThanh = maTrangThai == "DA_HOAN_THANH";
    bool coTheHuy = booking['coTheHuy'] ?? false;

    // Define colors based on status
    Color statusColor;
    IconData statusIcon;
    if (daHuy) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
      tenTrangThai = "Đã hủy";
    } else if (hoanThanh) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = Colors.orange.shade700; // Chờ xác nhận/Đang phục vụ
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight( // Để thanh màu bên trái tự giãn
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Color Bar Indicator (Thanh màu bên trái)
              Container(
                width: 6,
                color: statusColor,
              ),
              
              // 2. Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Table Name & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['tenBan'] ?? booking['TenBan'] ?? "Bàn ?",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  tenTrangThai,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Info Rows
                      _buildInfoRow(Icons.receipt_long, "Mã: ${booking['maDonHang'] ?? booking['MaDonHang'] ?? 'N/A'}"),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.calendar_today, formattedTime),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.people_outline, "${booking['soLuongNguoi'] ?? booking['SoLuongNguoi'] ?? 0} khách"),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.grey.shade100, height: 1),
                      ),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Button Detail (Luôn hiện)
                          OutlinedButton(
                            onPressed: () => _showBookingDetail(booking['maDonHang'] ?? booking['MaDonHang'] ?? ""),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _wineRed,
                              side: BorderSide(color: _wineRed.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Chi tiết"),
                          ),
                          
                          // Button Cancel (Nếu được phép)
                          if (coTheHuy) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _cancelBooking(booking['maDonHang'] ?? booking['MaDonHang'] ?? ""),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                ),
                              ),
                              child: const Text("Hủy bàn"),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}