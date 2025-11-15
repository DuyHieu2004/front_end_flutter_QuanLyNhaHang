import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/danh_muc.dart';
import 'api_constants.dart';

class DanhMucService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<List<DanhMuc>> fetchDanhMucs() async {
    var uri = Uri.parse('$_baseUrl/DanhMucAPI');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => DanhMuc.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load categories from API');
    }
  }
}