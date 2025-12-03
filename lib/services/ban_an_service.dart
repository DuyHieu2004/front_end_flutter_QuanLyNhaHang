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

  // Lấy bàn có sẵn theo thời gian (giống web khách hàng - dùng GetStatusByTime)
  Future<List<BanAn>> fetchAvailableTables(DateTime selectedTime, int soNguoi, String maKhachHang) async {
    try {
      // In ra để kiểm tra xem giờ gửi đi là giờ gì
      print("--- DEBUG fetchAvailableTables ---");
      print("Time gửi đi: ${selectedTime.toIso8601String()}");
      print("Số người: $soNguoi");

      // Sử dụng GetStatusByTime như web khách hàng (không truyền maKhachHang trong query)
      // Backend sẽ tự xác định bàn "Của tôi" từ token nếu có
      final dateTimeStr = selectedTime.toIso8601String();
      var uri = Uri.parse('$_baseUrl/BanAnsAPI/GetStatusByTime').replace(queryParameters: {
        'dateTime': dateTimeStr,
        'soNguoi': soNguoi.toString(),
      });

      print("URL: $uri");

      // Lấy token nếu có để backend xác định bàn "Của tôi"
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      };
      
      // Thêm token vào header nếu có (giống web)
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print("Có token, đã thêm vào header");
      } else {
        print("Không có token");
      }

      print("Đang gọi API...");
      final response = await http.get(uri, headers: headers);

      print("Response Status: ${response.statusCode}");
      print("Response Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");

      if (response.statusCode == 200) {
        try {
          List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
          print("Số bàn nhận được: ${jsonResponse.length}");
          
          // Parse từng bàn và bắt lỗi nếu có
          final tables = <BanAn>[];
          for (var i = 0; i < jsonResponse.length; i++) {
            try {
              final table = BanAn.fromJson(jsonResponse[i]);
              tables.add(table);
            } catch (e) {
              print("Lỗi parse bàn thứ ${i + 1}: $e");
              print("Data: ${jsonResponse[i]}");
              // Bỏ qua bàn lỗi, tiếp tục với các bàn khác
            }
          }
          
          print("Số bàn parse thành công: ${tables.length}");
          
          // Backend sẽ tự động trả về trạng thái "CuaTui" cho các bàn của khách hàng đã đăng nhập
          return tables;
        } catch (e, stackTrace) {
          print("Lỗi parse JSON: $e");
          print("Stack trace: $stackTrace");
          print("Response body: ${response.body}");
          throw Exception('Lỗi parse dữ liệu từ server: $e');
        }
      } else {
        print('Lỗi tải bàn: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Lỗi tải bàn: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print("=== LỖI TRONG fetchAvailableTables ===");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      print("=====================================");
      rethrow;
    }
  }

  // Lấy chi tiết đơn hàng/hóa đơn (giống web: có thể lấy theo maDonHang hoặc maBan)
  Future<Map<String, dynamic>> getMyBookingDetail({
    String? maDonHang,
    String? maBan,
    DateTime? selectedTime,
  }) async {
    print("========================================");
    print("--- BẮT ĐẦU GỌI API CHI TIẾT ĐẶT BÀN ---");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // 1. Check Token
    if (token == null || token.isEmpty) {
      print("LỖI: Token bị null hoặc rỗng trong SharedPreferences");
      throw Exception('Bạn chưa đăng nhập (Token không tìm thấy). Vui lòng đăng nhập lại.');
    } else {
      print("Token OK: ${token.substring(0, 10)}...");
    }

    // 2. Tạo URL với query parameters (giống web)
    final queryParams = <String, String>{};
    if (maDonHang != null && maDonHang.isNotEmpty) {
      queryParams['maDonHang'] = maDonHang;
    }
    if (maBan != null && maBan.isNotEmpty) {
      queryParams['maBan'] = maBan;
      // Tự động thêm thời gian hiện tại nếu tìm theo bàn (giống web)
      queryParams['dateTime'] = (selectedTime ?? DateTime.now()).toIso8601String();
    }

    var uri = Uri.parse('$_baseUrl/DonHangsAPI/GetMyBookingDetail')
        .replace(queryParameters: queryParams);

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
    print("Response Body: ${response.body}");

    // 4. Xử lý kết quả
    if (response.statusCode == 200) {
      print("--- THÀNH CÔNG ---");
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      print("--- LỖI 401: Token hết hạn hoặc không hợp lệ ---");
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 404) {
      String loiNhanDuoc = response.body;
      print("--- LỖI 404: Không tìm thấy ---");
      throw Exception('Không tìm thấy đơn: $loiNhanDuoc');
    } else {
      print("--- LỖI KHÁC: ${response.statusCode} ---");
      throw Exception('Lỗi (${response.statusCode}): ${response.body}');
    }
  }

}