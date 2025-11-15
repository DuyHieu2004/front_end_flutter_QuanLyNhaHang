import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dat_ban_dto.dart';
import 'api_constants.dart';

class DatBanService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>> createBooking(DatBanDto dto) async {
    var uri = Uri.parse('$_baseUrl/DatBanAPI/TaoDatBan');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // Nhớ dùng jsonEncode để đảm bảo format chuẩn
        body: jsonEncode(dto.toJson()),
      );

      // Giải mã kết quả trả về từ Server
      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // --- ĐÂY LÀ KHÚC QUAN TRỌNG BẠN CẦN ---
        // Trả về đầy đủ dữ liệu để Provider quyết định có mở cổng thanh toán hay không
        return {
          'success': true,
          'message': responseBody['message'],

          // Các trường phục vụ thanh toán (Lấy từ JSON server trả về)
          // Dùng ?? để tránh lỗi null nếu server không trả về
          'requirePayment': responseBody['requirePayment'] ?? false,
          'paymentUrl': responseBody['paymentUrl'] ?? '',
          'depositAmount': responseBody['depositAmount'] ?? 0,
        };
      } else {
        // Trường hợp thất bại (Lỗi 400, 500...)
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Đặt bàn thất bại'
        };
      }
    } catch (e) {
      // Trường hợp lỗi mạng hoặc lỗi code
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ: $e'
      };
    }
  }
}