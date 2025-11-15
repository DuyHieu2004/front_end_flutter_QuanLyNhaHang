// lib/providers/dat_ban_provider.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:front_end_app/services/dat_ban_service.dart';
import 'package:intl/intl.dart';
import '../models/dat_ban_dto.dart';


class DatBanProvider with ChangeNotifier {

  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 30));

  final _datBanService = DatBanService();

  bool get isLoading => _isLoading;
  DateTime get selectedDateTime => _selectedDateTime;


  // Hàm chọn ngày giờ
  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    // 1. Chọn Ngày
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime, // Mặc định chọn ngày hiện tại (hoặc ngày đã chọn)

      // === RÀNG BUỘC LỊCH ===
      firstDate: now, // Không cho chọn quá khứ
      lastDate: now.add(const Duration(days: 14)), // Chỉ cho chọn trong vòng 14 ngày tới
      // ======================

      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 2. Chọn Giờ (TimePicker)
      if (!context.mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        // Ghép Ngày + Giờ lại
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // === KIỂM TRA LOGIC 30 PHÚT Ở ĐÂY (VALIDATE UI) ===
        if (newDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vui lòng đặt trước ít nhất 30 phút!"),
              backgroundColor: Colors.orange,
            ),
          );
          return; // Không lưu, bắt chọn lại
        }

        // Nếu hợp lệ thì lưu
        _selectedDateTime = newDateTime;
        notifyListeners();
      }
    }
  }


  Future<void> submitBooking({
    required BuildContext context,
    required DatBanDto dto,
    required VoidCallback onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();

    // 1. Gọi API
    final result = await _datBanService.createBooking(dto);

    _isLoading = false;
    notifyListeners();

    if (!context.mounted) return;

    // 2. TRƯỜNG HỢP THẤT BẠI
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
      return; // Dừng lại, không làm gì nữa
    }

    // 3. TRƯỜNG HỢP THÀNH CÔNG - NHƯNG CẦN THANH TOÁN (CỌC)
    // Kiểm tra xem backend có yêu cầu cọc không
    if (result['requirePayment'] == true) {
      String paymentUrl = result['paymentUrl'];
      double amount = double.tryParse(result['depositAmount'].toString()) ?? 0;

      // Hiện Dialog bắt buộc thanh toán
      _showPaymentDialog(context, paymentUrl, amount);

      // LƯU Ý: Không gọi onSuccess() ở đây vì chưa xong,
      // khách phải thanh toán xong mới tính là xong.
      return;
    }

    // 4. TRƯỜNG HỢP THÀNH CÔNG - KHÔNG CẦN CỌC
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: Colors.green,
      ),
    );

    onSuccess(); // Đóng màn hình đặt bàn
  }

// === HÀM PHỤ: HIỆN HỘP THOẠI THANH TOÁN ===
  void _showPaymentDialog(BuildContext context, String url, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc phải chọn, không bấm ra ngoài được
      builder: (ctx) => AlertDialog(
        title: const Text("Yêu cầu đặt cọc"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 50, color: Colors.orange),
            const SizedBox(height: 10),
            Text("Đơn đặt bàn này cần đặt cọc:"),
            Text(
              "${NumberFormat("#,###").format(amount)} VNĐ",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 10),
            const Text("Vui lòng thanh toán để hoàn tất giữ chỗ."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Đóng dialog
            child: const Text("Để sau"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog trước

              // Mở trình duyệt thanh toán (VNPAY/Momo)
              // Nếu bạn đã cài url_launcher thì dùng dòng dưới:
              // await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

              // Nếu CHƯA cài url_launcher thì in ra console để test:
              print(">>> MỞ URL THANH TOÁN: $url");

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đang mở cổng thanh toán..."))
              );
            },
            child: const Text("Thanh toán ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void resetState() {
    _isLoading = false;
    _selectedDateTime = DateTime.now().add(const Duration(minutes: 30));
  }
}