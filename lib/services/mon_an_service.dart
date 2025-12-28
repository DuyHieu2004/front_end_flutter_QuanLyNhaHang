import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mon_an.dart';
import 'api_constants.dart';

class MonAnService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<List<MonAn>> fetchMonAns({String? maDanhMuc, String? searchString}) async {
    try {
      var uri = Uri.parse('$_baseUrl/MonAnsAPI');
      final Map<String, String> queryParameters = {};

      if (maDanhMuc != null && maDanhMuc.isNotEmpty) {
        queryParameters['maDanhMuc'] = maDanhMuc;
      }
      if (searchString != null && searchString.isNotEmpty) {
        queryParameters['searchString'] = searchString;
      }

      if (queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Xử lý response có thể là array hoặc object với data property
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));
        
        List<dynamic> jsonResponse = [];
        if (decodedBody is List) {
          jsonResponse = decodedBody;
        } else if (decodedBody is Map) {
          // Xử lý cả PascalCase và camelCase
          if (decodedBody.containsKey('data')) {
            jsonResponse = decodedBody['data'] is List ? decodedBody['data'] : [];
          } else if (decodedBody.containsKey('Data')) {
            jsonResponse = decodedBody['Data'] is List ? decodedBody['Data'] : [];
          } else if (decodedBody.containsKey('success') && decodedBody['success'] == true) {
            final data = decodedBody['data'] ?? decodedBody['Data'];
            jsonResponse = data is List ? data : [];
          }
        }
        
        // Parse từng món ăn và bỏ qua các món lỗi
        final monAns = <MonAn>[];
        for (var i = 0; i < jsonResponse.length; i++) {
          try {
            final monAn = MonAn.fromJson(jsonResponse[i] as Map<String, dynamic>);
            monAns.add(monAn);
          } catch (e) {
            print('Error parsing MonAn at index $i: $e');
            print('Data: ${jsonResponse[i]}');
            // Bỏ qua món lỗi, tiếp tục với các món khác
          }
        }
        
        return monAns;
      } else {
        throw Exception('Failed to load dishes from API. Status Code: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchMonAns: $e');
      rethrow;
    }
  }
}