import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodels/menu_view_model.dart';
import '../services/menu_service.dart';
import '../services/api_constants.dart';
import '../models/menu.dart';
import '../models/mon_an.dart';
import '../models/danh_muc.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MenuService _menuService = MenuService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name';
  String? _selectedCategory;
  
  // Menu đang áp dụng (theo khung giờ hiện tại)
  List<Menu> _menusDangApDung = [];
  bool _loadingMenusDangApDung = false;
  String? _tenKhungGio;
  int _timeRemaining = 0;
  
  // Timers để tránh memory leak
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  
  // Thực đơn điện tử - món ăn theo danh mục
  List<MonAn> _monAnsTheoDanhMuc = [];
  List<DanhMuc> _danhMucsEMenu = [];
  bool _loadingEMenu = false;
  String? _selectedEMenuCategory;
  bool _hasFetchedMenuViewModel = false;
  bool _hasInitializedMenuData = false;
  
  // Tất cả món
  List<MonAn> _allMonAns = [];
  bool _loadingAllMon = false;
  List<String> _categories = [];
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Khởi tạo dữ liệu sau khi build để tránh notifyListeners trong build
    Future.microtask(_initMenuData);
    
    // Setup countdown timer
    _startCountdownTimer();
  }

  Future<void> _initMenuData() async {
    if (_hasInitializedMenuData) return;
    _hasInitializedMenuData = true;

    await _loadMenusDangApDung();
    await _loadAllMonAns();
    await _loadCategories();
    await _loadEMenuData();
  }

  Future<void> _ensureMenuViewModelData() async {
    if (_hasFetchedMenuViewModel) return;
    final viewModel = Provider.of<MenuViewModel>(context, listen: false);
    await viewModel.fetchInitialData();
    _hasFetchedMenuViewModel = true;
  }

  void _startCountdownTimer() {
    // Hủy timers cũ nếu có
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    
    // Countdown timer mỗi giây
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _timeRemaining <= 0) {
        timer.cancel();
        if (_timeRemaining <= 0) {
          // Reload menu khi hết thời gian
    _loadMenusDangApDung();
        }
        return;
      }
      setState(() {
        _timeRemaining--;
      });
    });
    
    // Refresh menu mỗi phút
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _loadMenusDangApDung();
    });
  }

  Future<void> _loadMenusDangApDung() async {
    setState(() => _loadingMenusDangApDung = true);
    try {
      // Dùng fetchMenuHienTai() để đồng bộ với React web
      final response = await _menuService.fetchMenuHienTai();
      
      // Parse response giống React web
      final data = response['data'] ?? [];
      final menus = (data as List).map((m) => Menu.fromJson(m)).toList();
      
      setState(() {
        _menusDangApDung = menus;
        _tenKhungGio = response['tenKhungGio'];
        _timeRemaining = response['timeRemaining'] ?? 0;
        _loadingMenusDangApDung = false;
      });
    } catch (e, stackTrace) {
      // Log error chi tiết để debug
      print('Error loading menus: $e');
      print('Stack trace: $stackTrace');
      
      // Hiển thị error message cho user nếu widget còn mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải menu. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      setState(() {
        _menusDangApDung = [];
        _tenKhungGio = null;
        _timeRemaining = 0;
        _loadingMenusDangApDung = false;
      });
    }
  }

  Future<void> _loadEMenuData() async {
    setState(() => _loadingEMenu = true);
    try {
      await _ensureMenuViewModelData();
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      setState(() {
        _monAnsTheoDanhMuc = viewModel.monAns;
        _danhMucsEMenu = viewModel.danhMucs;
        _loadingEMenu = false;
      });
    } catch (e, stackTrace) {
      print('Error loading E-menu data: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thực đơn điện tử. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      setState(() {
        _monAnsTheoDanhMuc = [];
        _danhMucsEMenu = [];
        _loadingEMenu = false;
      });
    }
  }

  String _getTenDanhMuc(String maDanhMuc) {
    final danhMuc = _danhMucsEMenu.firstWhere(
      (dm) => dm.maDanhMuc == maDanhMuc,
      orElse: () => DanhMuc(maDanhMuc: maDanhMuc, tenDanhMuc: 'Khác'),
    );
    return danhMuc.tenDanhMuc;
  }

  Future<void> _loadAllMonAns() async {
    setState(() => _loadingAllMon = true);
    try {
      await _ensureMenuViewModelData();
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      setState(() {
        _allMonAns = viewModel.monAns;
        _loadingAllMon = false;
      });
    } catch (e, stackTrace) {
      print('Error loading all dishes: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách món ăn. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      setState(() {
        _allMonAns = [];
        _loadingAllMon = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      await _ensureMenuViewModelData();
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      setState(() {
        _categories = viewModel.danhMucs.map((dm) => dm.tenDanhMuc).toList();
      });
    } catch (e, stackTrace) {
      print('Error loading categories: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _categories = [];
      });
    }
  }

  List<MonAn> get _filteredMonAns {
    var filtered = _allMonAns;
    
    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      if (viewModel.danhMucs.isNotEmpty) {
      final category = viewModel.danhMucs.firstWhere(
        (dm) => dm.tenDanhMuc == _selectedCategory,
        orElse: () => viewModel.danhMucs.first,
      );
      filtered = filtered.where((m) => m.maDanhMuc == category.maDanhMuc).toList();
      }
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.tenMonAn.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Sort
    if (_sortBy == 'price-asc') {
      filtered.sort((a, b) => a.gia.compareTo(b.gia));
    } else if (_sortBy == 'price-desc') {
      filtered.sort((a, b) => b.gia.compareTo(a.gia));
    } else {
      filtered.sort((a, b) => a.tenMonAn.compareTo(b.tenMonAn));
    }
    
    return filtered;
  }

  List<MonAn> get _paginatedMonAns {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _filteredMonAns.sublist(
      start,
      end > _filteredMonAns.length ? _filteredMonAns.length : end,
    );
  }

  int get _totalPages => (_filteredMonAns.length / _itemsPerPage).ceil();

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Cleanup timers để tránh memory leak
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text(
          'Thực đơn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.15,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple.shade700,
          indicatorWeight: 3,
          labelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Menu'),
            Tab(text: 'Thực đơn điện tử'),
            Tab(text: 'Tất cả món'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuDangApDung(),
          _buildEMenuView(),
          _buildAllMonView(),
        ],
      ),
    );
  }

  Widget _buildMenuDangApDung() {
    if (_loadingMenusDangApDung) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMenusDangApDung,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade600, Colors.indigo.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tenKhungGio != null ? 'Menu $_tenKhungGio' : 'Menu Đang Áp Dụng',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tenKhungGio != null 
                                ? 'Menu sẽ tự động thay đổi theo khung giờ'
                                : 'Danh sách menu hiện đang được áp dụng',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Hiển thị countdown timer nếu có
                  if (_timeRemaining > 0 && _tenKhungGio != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Còn lại trong khung giờ này:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          _formatTime(_timeRemaining),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(),
            const SizedBox(height: 24),
            
            // Danh sách menu
            if (_menusDangApDung.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có menu nào đang áp dụng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng quay lại sau',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                cacheExtent: 500, // Cache items ngoài viewport để tối ưu performance
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.7,
                ),
                itemCount: _menusDangApDung.length,
                itemBuilder: (context, index) {
                  final menu = _menusDangApDung[index];
                  return RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildMenuCard(menu, index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEMenuView() {
    if (_loadingEMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    // Lọc món ăn theo danh mục đã chọn
    List<MonAn> filteredMonAns = _monAnsTheoDanhMuc;
    if (_selectedEMenuCategory != null && _selectedEMenuCategory!.isNotEmpty) {
      // Tìm maDanhMuc từ tenDanhMuc
      final selectedDanhMuc = _danhMucsEMenu.firstWhere(
        (dm) => dm.tenDanhMuc == _selectedEMenuCategory,
        orElse: () => DanhMuc(maDanhMuc: '', tenDanhMuc: ''),
      );
      if (selectedDanhMuc.maDanhMuc.isNotEmpty) {
        filteredMonAns = _monAnsTheoDanhMuc
            .where((monAn) => monAn.maDanhMuc == selectedDanhMuc.maDanhMuc)
            .toList();
      }
    }

    // Nhóm món ăn theo danh mục
    Map<String, List<MonAn>> monAnsByCategory = {};
    for (var monAn in filteredMonAns) {
      String category = _getTenDanhMuc(monAn.maDanhMuc);
      if (!monAnsByCategory.containsKey(category)) {
        monAnsByCategory[category] = [];
      }
      monAnsByCategory[category]!.add(monAn);
    }

    return RefreshIndicator(
      onRefresh: _loadEMenuData,
      child: Column(
        children: [
          // Filter danh mục
          if (_danhMucsEMenu.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildEMenuCategoryChip('Tất cả', null),
                  const SizedBox(width: 8),
                  ..._danhMucsEMenu.map((dm) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildEMenuCategoryChip(dm.tenDanhMuc, dm.tenDanhMuc),
                  )),
                ],
              ),
            ),
          
          // Danh sách món ăn theo danh mục
          Expanded(
            child: monAnsByCategory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Chưa có món ăn nào',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: monAnsByCategory.length,
                    itemBuilder: (context, categoryIndex) {
                      final category = monAnsByCategory.keys.elementAt(categoryIndex);
                      final monAns = monAnsByCategory[category]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề danh mục
                          Padding(
                            padding: EdgeInsets.only(bottom: 12, top: categoryIndex > 0 ? 24 : 0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade600,
                                        Colors.indigo.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${monAns.length} món)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Grid món ăn
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            cacheExtent: 500, // Cache items để tối ưu performance
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: monAns.length,
                            itemBuilder: (context, index) {
                              return RepaintBoundary(
                                child: _buildMonAnCard(monAns[index], index),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEMenuCategoryChip(String label, String? value) {
    final isSelected = _selectedEMenuCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedEMenuCategory = selected ? value : null;
        });
      },
      selectedColor: Colors.deepPurple.shade600,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple.shade700 : Colors.grey.shade300,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }

  Widget _buildAllMonView() {
    return Column(
      children: [
        // Search và Sort
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món ăn, mô tả, danh mục...',
                  prefixIcon: Icon(Icons.search, color: Colors.deepPurple.shade700),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.sort, color: Colors.deepPurple.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.grey.shade800),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Sắp xếp: Tên A-Z')),
                        DropdownMenuItem(value: 'price-asc', child: Text('Giá: Thấp → Cao')),
                        DropdownMenuItem(value: 'price-desc', child: Text('Giá: Cao → Thấp')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? 'name';
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Filter tags
              if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Chip(
                        label: Text('Tìm: "$_searchQuery"'),
                        onDeleted: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _currentPage = 1;
                          });
                        },
                      ),
                    if (_selectedCategory != null)
                      Chip(
                        label: Text('Danh mục: $_selectedCategory'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedCategory = null;
                            _currentPage = 1;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Category filters
        if (_categories.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('Tất cả', null),
                const SizedBox(width: 8),
                ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(cat, cat),
                )),
              ],
            ),
          ),
        
        // Grid món ăn
        Expanded(
          child: _loadingAllMon
              ? _buildShimmerGrid()
              : _filteredMonAns.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            cacheExtent: 500, // Cache items để tối ưu performance
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _paginatedMonAns.length,
                            itemBuilder: (context, index) {
                              final monAn = _paginatedMonAns[index];
                              return RepaintBoundary(
                                child: _buildMonAnCard(monAn, index),
                              );
                            },
                          ),
                        ),
                        
                        // Pagination
                        if (_totalPages > 1) _buildPagination(),
                        
                        // Info
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Hiển thị ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, _filteredMonAns.length)} trong tổng số ${_filteredMonAns.length} món',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? value : null;
          _currentPage = 1;
        });
      },
      selectedColor: Colors.deepPurple.shade700,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple.shade700 : Colors.grey.shade300,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }

  Widget _buildMenuCard(Menu menu, int index) {
    final imageUrl = menu.hinhAnh != null && menu.hinhAnh!.isNotEmpty
        ? (menu.hinhAnh!.startsWith('http')
            ? menu.hinhAnh!
            : '${ApiConstants.imageBaseUrl}${menu.hinhAnh!.startsWith('/') ? '' : '/'}${menu.hinhAnh}')
        : null;

    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMenuDetail(menu),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl != null
                        ? SizedBox.expand(
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade100,
                                        Colors.deepPurple.shade50,
                                      ],
                                    ),
                                  ),
                                  child: Icon(Icons.restaurant_menu, size: 50, color: Colors.deepPurple.shade700),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade100,
                                  Colors.deepPurple.shade50,
                                ],
                              ),
                            ),
                            child: Icon(Icons.restaurant_menu, size: 50, color: Colors.deepPurple.shade700),
                          ),
                  ),
                  // Badge giảm giá
                  if (menu.phanTramGiamGia != null && menu.phanTramGiamGia! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade600, Colors.red.shade400],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${menu.phanTramGiamGia!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phần trên: Tên và loại menu
                    Flexible(
                      flex: 1,
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  menu.tenMenu,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (menu.loaiMenu != null && menu.loaiMenu!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      menu.loaiMenu!,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.deepPurple.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          // Số món trong menu
                          if (menu.chiTietMenus != null && menu.chiTietMenus!.isNotEmpty)
                            Text(
                              '${menu.chiTietMenus!.length} món',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              'Combo',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Phần dưới: Giá
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Giá gốc và phần trăm giảm giá (nếu có)
                        if (menu.giaGoc != null && menu.giaGoc! > 0 && menu.giaMenu != null && menu.giaGoc! > menu.giaMenu!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${NumberFormat("#,###").format(menu.giaGoc!.toInt())} đ',
                                    style: TextStyle(
                                      fontSize: 9,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (menu.phanTramGiamGia != null && menu.phanTramGiamGia! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${menu.phanTramGiamGia!.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // Giá hiện tại
                        if (menu.giaMenu != null && menu.giaMenu! > 0)
                          Text(
                            '${NumberFormat("#,###").format(menu.giaMenu!.toInt())} đ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'Liên hệ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMonAnCard(MonAn monAn, int index) {
    // Xử lý hình ảnh - đồng bộ với web (xử lý cả relative và absolute URL)
    String? imageUrl;
    if (monAn.hinhAnhMonAns.isNotEmpty) {
      final rawUrl = monAn.hinhAnhMonAns.first.urlHinhAnh;
      if (rawUrl.isNotEmpty) {
        // Nếu đã là absolute URL (http/https), dùng trực tiếp
        if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
          imageUrl = rawUrl;
        } else {
          // Nếu là relative path, ghép với base URL
          final cleanUrl = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
          imageUrl = '${ApiConstants.imageBaseUrl}/$cleanUrl';
        }
      }
    }
    
    // Kiểm tra trạng thái còn hàng/hết hàng
    final conHang = monAn.phienBanMonAns.isEmpty 
        ? true 
        : monAn.phienBanMonAns.any((pb) => 
            pb.maTrangThai == null || 
            pb.maTrangThai!.toUpperCase() != 'HET_HANG');

    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: conHang ? () => _showMonAnDetail(monAn) : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? SizedBox.expand(
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple.shade100,
                                    Colors.deepPurple.shade50,
                                  ],
                                ),
                              ),
                              child: Icon(Icons.restaurant_menu, size: 50, color: Colors.deepPurple.shade700),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade100,
                              Colors.deepPurple.shade50,
                            ],
                          ),
                        ),
                        child: Icon(Icons.restaurant_menu, size: 50, color: Colors.deepPurple.shade700),
                      ),
                  ),
                  // Overlay "HẾT HÀNG" nếu không còn hàng
                  if (!conHang)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          'HẾT HÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phần trên: Tên món ăn
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monAn.tenMonAn,
                          style: const TextStyle(
                            fontSize: 13.2,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monAn.tenDanhMuc != null && monAn.tenDanhMuc!.isNotEmpty
                              ? monAn.tenDanhMuc!
                              : _getTenDanhMuc(monAn.maDanhMuc),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (monAn.phienBanMonAns.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            monAn.phienBanMonAns.length == 1
                                ? '${monAn.phienBanMonAns.first.tenPhienBan}'
                                : '${monAn.phienBanMonAns.length} size',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.deepPurple.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Phần dưới: Giá - đồng bộ với web
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hiển thị giá từ phiên bản hoặc giá mặc định
                        Builder(
                          builder: (context) {
                            if (monAn.phienBanMonAns.isNotEmpty) {
                              final prices = monAn.phienBanMonAns
                                  .where((pb) => pb.gia > 0)
                                  .map((pb) => pb.gia)
                                  .toList();
                              
                              if (prices.isEmpty) {
                                return Text(
                                  'Liên hệ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              }
                              
                              final minPrice = prices.reduce((a, b) => a < b ? a : b);
                              final maxPrice = prices.reduce((a, b) => a > b ? a : b);
                              
                              // Nếu có nhiều phiên bản với giá khác nhau, hiển thị khoảng giá
                              if (monAn.phienBanMonAns.length > 1 && minPrice != maxPrice) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${NumberFormat("#,###").format(minPrice.toInt())} đ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                    Text(
                                      '- ${NumberFormat("#,###").format(maxPrice.toInt())} đ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Nếu chỉ có 1 phiên bản hoặc tất cả cùng giá, hiển thị giá duy nhất
                                return Text(
                                  '${NumberFormat("#,###").format(minPrice.toInt())} đ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                );
                              }
                            } else if (monAn.gia > 0) {
                              return Text(
                            '${NumberFormat("#,###").format(monAn.gia.toInt())} đ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                              );
                            } else {
                              return Text(
                            'Liên hệ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                              );
                            }
                          },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(color: Colors.grey[300]),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty || _selectedCategory != null
                      ? Icons.search_off
                      : Icons.restaurant_menu_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy món nào'
                    : _selectedCategory != null
                        ? 'Chưa có món nào trong danh mục này'
                        : 'Chưa có món nào trong thực đơn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_searchQuery.isNotEmpty)
                Text(
                  'Thử tìm kiếm với từ khóa khác',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_selectedCategory != null)
                Text(
                  'Vui lòng chọn danh mục khác',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Vui lòng thử lại sau',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...List.generate(_totalPages, (index) {
            final page = index + 1;
            if (page == 1 ||
                page == _totalPages ||
                (page >= _currentPage - 1 && page <= _currentPage + 1)) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentPage = page),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage == page
                        ? Colors.indigo.shade600
                        : Colors.grey.shade200,
                    foregroundColor: _currentPage == page ? Colors.white : Colors.black87,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('$page'),
                ),
              );
            } else if (page == _currentPage - 2 || page == _currentPage + 2) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Colors.grey)),
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showMenuDetail(Menu menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.tenMenu,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (menu.loaiMenu != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              menu.loaiMenu!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (menu.hinhAnh != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          menu.hinhAnh!.startsWith('http')
                              ? menu.hinhAnh!
                              : '${ApiConstants.imageBaseUrl}${menu.hinhAnh!.startsWith('/') ? '' : '/'}${menu.hinhAnh}',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant_menu, size: 64),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Price
                    if (menu.giaMenu != null) ...[
                      const Text(
                        'Giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${NumberFormat("#,###").format(menu.giaMenu!.toInt())} đ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade600,
                            ),
                          ),
                          if (menu.giaGoc != null && menu.giaGoc! > menu.giaMenu!) ...[
                            const SizedBox(width: 16),
                            Text(
                              NumberFormat("#,###").format(menu.giaGoc!.toInt()),
                              style: TextStyle(
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            if (menu.phanTramGiamGia != null && menu.phanTramGiamGia! > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Giảm ${menu.phanTramGiamGia!.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Description
                    if (menu.moTa != null && menu.moTa!.isNotEmpty) ...[
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        menu.moTa!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Chi tiết món
                    if (menu.chiTietMenus != null && menu.chiTietMenus!.isNotEmpty) ...[
                      Text(
                        'Danh sách món (${menu.chiTietMenus!.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...menu.chiTietMenus!.map((ct) {
                        final imageUrl = ct.monAn?.hinhAnh != null
                            ? (ct.monAn!.hinhAnh!.startsWith('http')
                                ? ct.monAn!.hinhAnh!
                                : '${ApiConstants.imageBaseUrl}${ct.monAn!.hinhAnh!.startsWith('/') ? '' : '/'}${ct.monAn!.hinhAnh}')
                            : null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.restaurant_menu),
                                      );
                                    },
                                  ),
                                ),
                              if (imageUrl != null) const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ct.monAn?.tenMonAn ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (ct.ghiChu != null && ct.ghiChu!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          ct.ghiChu!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (ct.monAn?.gia != null)
                                Text(
                                  '${NumberFormat("#,###").format(ct.monAn!.gia!.toInt())} đ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              if (ct.soLuong != null && ct.soLuong! > 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'x${ct.soLuong}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonAnDetail(MonAn monAn) {
    // Xử lý hình ảnh - đồng bộ với web
    String? imageUrl;
    if (monAn.hinhAnhMonAns.isNotEmpty) {
      final rawUrl = monAn.hinhAnhMonAns.first.urlHinhAnh;
      if (rawUrl.isNotEmpty) {
        if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
          imageUrl = rawUrl;
        } else {
          final cleanUrl = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
          imageUrl = '${ApiConstants.imageBaseUrl}/$cleanUrl';
        }
      }
    }
    
    // Tính giá để hiển thị
    String priceText = 'Liên hệ';
    if (monAn.phienBanMonAns.isNotEmpty) {
      final prices = monAn.phienBanMonAns
          .where((pb) => pb.gia > 0)
          .map((pb) => pb.gia)
          .toList();
      if (prices.isNotEmpty) {
        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);
        if (minPrice == maxPrice) {
          priceText = '${NumberFormat("#,###").format(minPrice.toInt())} đ';
        } else {
          priceText = '${NumberFormat("#,###").format(minPrice.toInt())} - ${NumberFormat("#,###").format(maxPrice.toInt())} đ';
        }
      }
    } else if (monAn.gia > 0) {
      priceText = '${NumberFormat("#,###").format(monAn.gia.toInt())} đ';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      monAn.tenMonAn,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant_menu, size: 64),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Hiển thị giá - đồng bộ với web
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giá',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                    Text(
                          priceText,
                      style: TextStyle(
                        fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                        // Hiển thị danh sách phiên bản nếu có nhiều
                        if (monAn.phienBanMonAns.length > 1) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Phiên bản & Giá',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...monAn.phienBanMonAns.map((pb) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pb.tenPhienBan,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat("#,###").format(pb.gia.toInt())} đ',
                                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
