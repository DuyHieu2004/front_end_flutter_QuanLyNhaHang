import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mon_an.dart';
import 'api_constants.dart';

class MonAnService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<List<MonAn>> fetchMonAns({String? maDanhMuc, String? searchString}) async {
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
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => MonAn.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load dishes from API');
    }
  }
}