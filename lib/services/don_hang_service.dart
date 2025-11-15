import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 1. Nhớ import cái này
import 'api_constants.dart';

class DonHangService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>> getMyBookingDetail({required String maDonHang}) async {
    final prefs = await SharedPreferences.getInstance();

    // --- SỬA LẠI CHỖ NÀY ---
    // Phải dùng key 'jwt_token' cho khớp với AuthService
    final String? token = prefs.getString('jwt_token');
    // -----------------------

    if (token == null || token.isEmpty) {
      // Ném lỗi này thì giao diện sẽ bắt được và hiện popup báo lỗi
      throw Exception('Bạn chưa đăng nhập (Không tìm thấy Token).');
    }

    final uri = Uri.parse('$_baseUrl/DonHangsAPI/GetMyBookingDetail').replace(
      queryParameters: {
        'maDonHang': maDonHang,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        // Xử lý các lỗi thường gặp
        if (response.statusCode == 401) {
          throw Exception('Phiên đăng nhập hết hạn.');
        }
        if (response.statusCode == 404) {
          throw Exception('Không tìm thấy đơn hàng (404).');
        }

        // Đọc lỗi từ server trả về nếu có
        final body = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(body['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu lỗi do mình throw ở trên thì ném tiếp, còn lỗi lạ thì bọc lại
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}