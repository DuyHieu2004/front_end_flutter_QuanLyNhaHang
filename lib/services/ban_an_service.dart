import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ban_an.dart';
import 'api_constants.dart';

class BanAnService {
  static const String _baseUrl = ApiConstants.baseUrl;


  Future<List<BanAn>> fetchBanAns() async {
    var uri = Uri.parse("$_baseUrl/BanAnsAPI");
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((data) => BanAn.fromJson(data)).toList();
    } else {
      throw Exception("Failed to load ban an from API");
    }
  }

  Future<List<BanAn>> fetchTableStatusByTime(DateTime selectedTime, int soNguoi) async {
    var uri = Uri.parse('$_baseUrl/BanAnsAPI/GetStatusByTime')
        .replace(queryParameters: {
      'dateTime': selectedTime.toIso8601String(),
      'soNguoi': soNguoi.toString(),
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((data) => BanAn.fromJson(data)).toList();
    } else {
      throw Exception(
          'Failed to load filtered tables. Status Code: ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<List<BanAn>> fetchAvailableTables(DateTime selectedTime, int soNguoi, String maKhachHang) async {
    // In ra để kiểm tra xem giờ gửi đi là giờ gì
    print("--- DEBUG fetchAvailableTables ---");
    print("Time gửi đi: ${selectedTime.toIso8601String()}");

    var uri = Uri.parse('$_baseUrl/BanAnsAPI/GetAvailableBanAns').replace(queryParameters: {
      'dateTime': selectedTime.toIso8601String(),
      'soNguoi': soNguoi.toString(),
      'maKhachHang': maKhachHang,
    });

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((data) => BanAn.fromJson(data)).toList();
    } else {
      print('Lỗi tải bàn: ${response.statusCode} - Body: ${response.body}');
      throw Exception('Lỗi tải bàn: ${response.statusCode}');
    }
  }

  // --- HÀM ĐANG BỊ LỖI 404 ---
  Future<Map<String, dynamic>> getMyBookingDetail(String maBan, DateTime selectedTime) async {

    print("========================================");
    print("--- BẮT ĐẦU GỌI API CHI TIẾT ĐẶT BÀN ---");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // 1. Check Token
    if (token == null || token.isEmpty) {
      print("LỖI: Token bị null hoặc rỗng trong SharedPreferences");
      throw Exception('Bạn chưa đăng nhập (Token không tìm thấy). Vui lòng đăng nhập lại.');
    } else {
      print("Token OK: ${token.substring(0, 10)}..."); // In 10 ký tự đầu để check
    }

    // 2. Tạo URL
    // Lưu ý: Server C# đôi khi cần format ngày tháng chuẩn, toIso8601String là tốt nhất
    var uri = Uri.parse('$_baseUrl/DonHangsAPI/GetMyBookingDetail').replace(queryParameters: {
      'maBan': maBan,
      'dateTime': selectedTime.toIso8601String(),
    });

    print("URL gọi đi: $uri");

    // 3. Gọi API
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}"); // <--- QUAN TRỌNG: Đọc lỗi từ Server trả về

    // 4. Xử lý kết quả
    if (response.statusCode == 200) {
      print("--- THÀNH CÔNG ---");
      return json.decode(utf8.decode(response.bodyBytes));
    }
    else if (response.statusCode == 401) {
      print("--- LỖI 401: Token hết hạn hoặc không hợp lệ ---");
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    else if (response.statusCode == 404) {
      // Nếu Server trả về text lỗi (ví dụ "Không tìm thấy thông tin đặt bàn"), ta lấy nó hiển thị luôn
      String loiNhanDuoc = response.body;
      print("--- LỖI 404: Không tìm thấy ---");
      // Ném lỗi kèm nội dung server trả về để hiển thị lên màn hình điện thoại
      throw Exception('Không tìm thấy đơn: $loiNhanDuoc');
    }
    else {
      print("--- LỖI KHÁC: ${response.statusCode} ---");
      throw Exception('Lỗi (${response.statusCode}): ${response.body}');
    }
  }

}