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
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _authService.getMyBookingHistory();
    });
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

          // 6. Load lại danh sách lịch sử ngay lập tức
          _loadHistory();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Sử Đặt Bàn"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải lịch sử: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("Bạn chưa có lịch sử đặt bàn nào.", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            );
          }

          var bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index];

              // Xử lý ngày giờ an toàn
              DateTime thoiGianBatDau;
              if (booking['thoiGianAn'] != null) {
                thoiGianBatDau = DateTime.parse(booking['thoiGianAn']);
              } else {
                thoiGianBatDau = DateTime.parse(booking['thoiGianDatHang'] ?? DateTime.now().toIso8601String());
              }

              String formattedTime = DateFormat('HH:mm, dd/MM/yyyy').format(thoiGianBatDau);

              print(booking);
              print("------------------------------");

              // Kiểm tra trạng thái
              String maTrangThai = booking['maTrangThai'] ?? "";
              String tenTrangThai = booking['trangThai'] ?? "Không rõ";
              print("Mã trạng thái: $maTrangThai");
              print("Tên trạng thái: $tenTrangThai");
              // print("------------------------------");
              //bool daHuy = maTrangThai == "DA_HUY";
              bool daHuy = booking['daHuy'] ;
             bool hoanThanh = maTrangThai == "DA_HOAN_THANH";

              // Logic nút hủy: Chưa hủy, Chưa xong, và Chưa quá giờ
             // bool coTheHuy = !daHuy && !hoanThanh && thoiGianBatDau.isAfter(DateTime.now());
              bool coTheHuy = booking['coTheHuy'] ;
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                child: ListTile(
                  // 2. QUAN TRỌNG: THÊM SỰ KIỆN TAP VÀO ĐÂY
                  onTap: () {
                    _showBookingDetail(booking['maDonHang']);
                  },

                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Icon(
                    daHuy ? Icons.cancel : (hoanThanh ? Icons.check_circle : Icons.access_time_filled),
                    color: daHuy ? Colors.red : (hoanThanh ? Colors.green : Colors.blue),
                    size: 40,
                  ),
                  title: Text(
                    booking['tenBan'] ?? "Bàn ?",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$formattedTime - ${booking['soLuongNguoi']} người"),
                      Text(
                        "Trạng thái: $tenTrangThai",
                        style: TextStyle(
                            color: daHuy ? Colors.red : Colors.black87,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                      // Hiển thị tiền cọc nếu có (để khách biết mà bấm vào xem chi tiết)
                      if (booking['tienDatCoc'] != null && booking['tienDatCoc'] > 0)
                        Text(
                          "Có cọc: ${NumberFormat("#,###").format(booking['tienDatCoc'])} đ",
                          style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic, fontSize: 12),
                        )
                    ],
                  ),
                  trailing: coTheHuy
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
                    onPressed: () => _cancelBooking(booking['maDonHang']),
                    child: const Text("Hủy", style: TextStyle(color: Colors.white)),
                  )
                      : const Icon(Icons.chevron_right), // Nếu không hủy được thì hiện mũi tên để biết là bấm vào được
                ),
              );
            },
          );
        },
      ),
    );
  }
}