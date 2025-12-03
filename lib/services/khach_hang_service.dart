import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class CustomerSearchResult {
  final bool found;
  final String? maKhachHang;
  final String? tenKhach;
  final String? email;
  final int? soLanAn;
  final bool? duocGiamGia;
  final String? message;

  CustomerSearchResult({
    required this.found,
    this.maKhachHang,
    this.tenKhach,
    this.email,
    this.soLanAn,
    this.duocGiamGia,
    this.message,
  });

  factory CustomerSearchResult.fromJson(Map<String, dynamic> json) {
    return CustomerSearchResult(
      found: json['found'] ?? false,
      maKhachHang: json['maKhachHang'],
      tenKhach: json['tenKhach'],
      email: json['email'],
      soLanAn: json['soLanAn'],
      duocGiamGia: json['duocGiamGia'],
      message: json['message'],
    );
  }
}

class KhachHangService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<CustomerSearchResult> searchByPhone(String phone) async {
    try {
      final uri = Uri.parse('$_baseUrl/DatBanAPI/TimKiemKhachHang/$phone');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return CustomerSearchResult.fromJson(jsonData);
      } else {
        return CustomerSearchResult(
          found: false,
          message: 'Không thể tra cứu khách hàng. Vui lòng thử lại.',
        );
      }
    } catch (e) {
      return CustomerSearchResult(
        found: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }
}

