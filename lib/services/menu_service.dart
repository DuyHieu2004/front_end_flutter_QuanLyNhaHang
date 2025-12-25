import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu.dart';
import 'api_constants.dart';

class MenuService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Lấy danh sách menu đang áp dụng
  Future<List<Menu>> fetchMenusDangApDung({String? maLoaiMenu}) async {
    try {
      String url = '$_baseUrl/MenuAPI/DangApDung';
      if (maLoaiMenu != null && maLoaiMenu.isNotEmpty) {
        url += '?maLoaiMenu=$maLoaiMenu';
      }
      
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        
        // Kiểm tra cấu trúc response
        if (jsonData is Map && jsonData.containsKey('data')) {
          List jsonResponse = jsonData['data'];
          return jsonResponse.map((data) => Menu.fromJson(data)).toList();
        } else if (jsonData is List) {
          return jsonData.map((data) => Menu.fromJson(data)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load menus: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching menus: $e');
      rethrow;
    }
  }

  /// Lấy menu theo khung giờ
  Future<List<Menu>> fetchMenusTheoKhungGio({String? khungGio}) async {
    try {
      String url = '$_baseUrl/MenuAPI/TheoKhungGio';
      if (khungGio != null && khungGio.isNotEmpty) {
        url += '?khungGio=$khungGio';
      }
      
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        
        if (jsonData is Map && jsonData.containsKey('data')) {
          List jsonResponse = jsonData['data'];
          return jsonResponse.map((data) => Menu.fromJson(data)).toList();
        } else if (jsonData is List) {
          return jsonData.map((data) => Menu.fromJson(data)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load menus: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching menus by time: $e');
      rethrow;
    }
  }

  /// Lấy menu hiện tại theo khung giờ tự động (đồng bộ với React web)
  /// API trả về: { success: true, khungGio, tenKhungGio, isNgayLe, timeRemaining, nextTimeSlot, data: [...] }
  Future<Map<String, dynamic>> fetchMenuHienTai() async {
    try {
      final uri = Uri.parse('$_baseUrl/MenuAPI/HienTai');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        
        if (jsonData is Map) {
          return Map<String, dynamic>.from(jsonData);
        } else {
          throw Exception('Unexpected response format: expected Map');
        }
      } else {
        throw Exception('Failed to load current menu: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching current menu: $e');
      rethrow;
    }
  }
}

