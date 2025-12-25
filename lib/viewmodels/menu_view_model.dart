import 'package:flutter/material.dart';
import 'package:front_end_app/services/danh_muc_service.dart';
import 'package:front_end_app/services/mon_an_service.dart';
import '../models/danh_muc.dart';
import '../models/mon_an.dart';

class MenuViewModel extends ChangeNotifier {


  final MonAnService _monAnService = MonAnService();
  final DanhMucService _danhMucService = DanhMucService();

  List<MonAn> _monAns = [];
  List<DanhMuc> _danhMucs = [];

  bool _isLoading = true;
  String? _selectedMaDanhMuc;
  String _searchQuery = '';


  List<MonAn> get monAns => _monAns;
  List<DanhMuc> get danhMucs => _danhMucs;
  bool get isLoading => _isLoading;
  String? get selectedMaDanhMuc => _selectedMaDanhMuc;

  MenuViewModel();


  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {

      final results = await Future.wait([
        _monAnService.fetchMonAns(),
        _danhMucService.fetchDanhMucs(),
      ]);
      _monAns = results[0] as List<MonAn>;
      _danhMucs = results[1] as List<DanhMuc>;
    } catch (e) {
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }


  void selectCategory(String? maDanhMuc) {
    _selectedMaDanhMuc = maDanhMuc;
    applyFilters();
  }


  void search(String query) {
    _searchQuery = query;
    applyFilters();
  }


  Future<void> applyFilters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _monAns = await _monAnService.fetchMonAns(
        maDanhMuc: _selectedMaDanhMuc,
        searchString: _searchQuery,
      );
    } catch (e) {
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}