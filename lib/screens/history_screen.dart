import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end_app/services/auth_service.dart';
import 'package:front_end_app/utils/QuickAlert.dart';
import 'booking_detail_screen.dart'; // <--- 1. NHỚ IMPORT MÀN HÌNH CHI TIẾT

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  
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

  // --- HÀM CHUYỂN HƯỚNG SANG CHI TIẾT ---
  void _showBookingDetail(String maDonHang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(maDonHang: maDonHang),
      ),
    );
  }

  void _cancelBooking(String maDonHang) async {
    // 1. Hỏi xác nhận trước
    QuickAlertService.showAlertConfirm(
      context,
      "Bạn có chắc chắn muốn hủy đơn đặt bàn này không?",
          () async {
        // 2. Hiện loading (khi người dùng bấm Đồng ý)
        QuickAlertService.showAlertLoading(context, "Đang xử lý hủy...");

        try {
          // 3. Gọi API Hủy
          // Nếu thành công thì chạy tiếp, thất bại thì nhảy xuống catch
          await _authService.cancelBooking(maDonHang);

          // 4. Tắt popup Loading
          Navigator.of(context, rootNavigator: true).pop();

          // 5. HIỆN THÔNG BÁO THÀNH CÔNG BẰNG QUICKALERT
          // (Thay thế cho showDialog cũ)
          QuickAlertService.showAlertSuccess(context, "Hủy đặt bàn thành công!");

          // 6. Reload lại kết quả tra cứu nếu đang có
          if (_searchResult != null && _phoneController.text.isNotEmpty) {
            _searchByPhone();
          }

        } catch (e) {
          // Xử lý lỗi
          Navigator.of(context, rootNavigator: true).pop(); // Tắt loading trước

          // Lọc bỏ chữ "Exception: " cho đẹp
          String errorMsg = e.toString().replaceAll("Exception: ", "");

          // Hiện thông báo lỗi
          QuickAlertService.showAlertFailure(context, errorMsg);
        }
      },
    );
  }

  Widget _buildBookingCard(dynamic booking, int index) {
    DateTime thoiGianBatDau;
    try {
      if (booking['thoiGianBatDau'] != null) {
        thoiGianBatDau = DateTime.parse(booking['thoiGianBatDau']);
      } else if (booking['thoiGianAn'] != null) {
        thoiGianBatDau = DateTime.parse(booking['thoiGianAn']);
      } else {
        thoiGianBatDau = DateTime.parse(booking['thoiGianDatHang'] ?? DateTime.now().toIso8601String());
      }
    } catch (e) {
      thoiGianBatDau = DateTime.now();
    }

    String formattedTime = DateFormat('HH:mm, dd/MM/yyyy').format(thoiGianBatDau);
    String? formattedDuKien;
    if (booking['thoiGianDuKien'] != null) {
      try {
        formattedDuKien = DateFormat('HH:mm, dd/MM/yyyy').format(DateTime.parse(booking['thoiGianDuKien']));
      } catch (e) {
        formattedDuKien = null;
      }
    }

    String maTrangThai = booking['maTrangThai'] ?? "";
    String tenTrangThai = booking['trangThai'] ?? "Không rõ";
    bool daHuy = booking['daHuy'] ?? false;
    bool hoanThanh = maTrangThai == "DA_HOAN_THANH";
    bool coTheHuy = booking['coTheHuy'] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: InkWell(
          onTap: () => _showBookingDetail(booking['maDonHang'] ?? booking['MaDonHang'] ?? ""),
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: daHuy
                    ? [Colors.red.shade50, Colors.red.shade100]
                    : hoanThanh
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: daHuy
                        ? Colors.red.shade200
                        : hoanThanh
                            ? Colors.green.shade200
                            : Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    daHuy
                        ? Icons.cancel
                        : hoanThanh
                            ? Icons.check_circle
                            : Icons.access_time_filled,
                    color: daHuy
                        ? Colors.red.shade900
                        : hoanThanh
                            ? Colors.green.shade900
                            : Colors.blue.shade900,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['tenBan'] ?? booking['TenBan'] ?? "Bàn ?",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: daHuy
                                  ? Colors.red.shade700
                                  : hoanThanh
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              daHuy ? "Đã hủy" : tenTrangThai,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "Mã đơn: ${booking['maDonHang'] ?? booking['MaDonHang'] ?? 'N/A'}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "Thời gian: $formattedTime",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      if (formattedDuKien != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "Dự kiến: $formattedDuKien",
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "Số khách: ${booking['soLuongNguoi'] ?? booking['SoLuongNguoi'] ?? 0}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (coTheHuy)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _cancelBooking(booking['maDonHang'] ?? booking['MaDonHang'] ?? ""),
                      child: const Text(
                        "Hủy",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Tra cứu lịch sử đặt bàn",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      hintText: "Nhập số điện thoại đã dùng để đặt bàn",
                      prefixIcon: Icon(Icons.phone, color: Colors.deepPurple.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchByPhone,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Icon(Icons.search, size: 22),
                    label: Text(
                      _isSearching ? "Đang tra cứu..." : "Xem lịch sử",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Hệ thống sẽ tìm theo đúng số điện thoại từng dùng khi đặt bàn.",
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_searchResult != null) ...[
            const SizedBox(height: 16),
            if (_searchResult!['message'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _searchResult!['message'],
                  style: TextStyle(color: Colors.blue.shade900),
                ),
              ),
            if (_searchResult!['customer'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchResult!['customer']['hoTen'] ?? "Khách hàng",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("SĐT: ${_searchResult!['customer']['soDienThoai'] ?? ''}"),
                    if (_searchResult!['customer']['email'] != null)
                      Text("Email: ${_searchResult!['customer']['email']}"),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_searchBookings.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "Khách hàng chưa có lịch sử đặt bàn.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._searchBookings.asMap().entries.map((entry) => _buildBookingCard(entry.value, entry.key)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Sử Đặt Bàn"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: _buildSearchTab(),
    );
  }
}