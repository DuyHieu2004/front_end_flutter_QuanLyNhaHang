import 'dart:convert';
import 'dart:io';
import 'package:front_end_app/services/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  final String _baseUrl = ApiConstants.baseUrl;
  final _storage = FlutterSecureStorage();


  Future<bool> checkUserExists(String identifier) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Auth/check-user'), // Đã có /Auth/
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'identifier': identifier}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['userExists'];
      }

      // Lỗi 500 (Backend sập)
      throw Exception('Lỗi máy chủ (${response.statusCode}): ${response.body}');

    } on SocketException catch (_) {
      // Lỗi kết nối (ví dụ: đang dùng localhost thay vì 10.0.2.2)
      throw Exception('Lỗi kết nối: Không thể kết nối đến $_baseUrl/Auth/check-user. Kiểm tra lại IP.');
    } catch (e) {
      rethrow;
    }
  }


  Future<bool> login(String identifier, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'identifier': identifier,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String token = data['token'];
        final String maKhachHang = data['maKhachHang'];
        final String hoTen = data['hoTen'];

        // KHỞI TẠO SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // LƯU TẤT CẢ VÀO ĐÂY (Dùng key 'jwt_token' thống nhất)
        await prefs.setString('jwt_token', token);
        await prefs.setString('maKhachHang', maKhachHang);
        await prefs.setString('hoTen', hoTen);

        return true;
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        throw Exception('Mã OTP không chính xác hoặc đã hết hạn.');
      }
      throw Exception('Lỗi máy chủ (${response.statusCode}): ${response.body}');

    } on SocketException catch (_) {
      throw Exception('Không thể kết nối đến máy chủ.');
    } catch (e) {
      rethrow;
    }
  }

  // --- 2. REGISTER: Cũng lưu vào SharedPreferences ---
  Future<bool> register(String identifier, String hoTen, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'identifier': identifier,
          'hoTen': hoTen,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String token = data['token'];

        // Lưu Token ngay lập tức
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        // LƯU Ý: Nếu API Register trả về cả maKhachHang thì lưu luôn ở đây nhé
        // Nếu không, người dùng có thể phải Login lại mới có maKhachHang
        if (data.containsKey('maKhachHang')) {
          await prefs.setString('maKhachHang', data['maKhachHang']);
        }

        return true;
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        throw Exception('Mã OTP không chính xác.');
      }
      throw Exception('Lỗi máy chủ: ${response.body}');

    } catch (e) {
      rethrow;
    }
  }

  // --- 3. HÀM LẤY TOKEN TỪ SHAREDPREFERENCES ---
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // Lấy đúng key đã lưu lúc Login
  }

  // --- 4. LOGOUT: Xóa sạch ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('maKhachHang');
    await prefs.remove('hoTen');
  }

  Future<String?> getUserNameFromToken() async {
    try {
      String? token = await getToken();
      if (token == null) return null;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['name'];
    } catch (e) {
      return null;
    }
  }

  // --- HÀM MỚI 1: LẤY TOKEN ĐỂ GỌI API BẢO MẬT ---
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getMyBookingHistory() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/BookingHistory/me'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Lỗi khi tải lịch sử: ${response.body}');
    }
  }

  Future<bool> cancelBooking(String maDonHang) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/BookingHistory/cancel/$maDonHang'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Lỗi khi hủy bàn: ${json.decode(response.body)['message']}');
    }
  }

}