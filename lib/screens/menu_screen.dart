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
  
  // Menu theo khung giờ
  List<Menu> _menusTheoKhungGio = [];
  bool _loadingKhungGio = false;
  String? _khungGioHienTai;
  String? _tenKhungGio;
  int _timeRemaining = 0;
  
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
    _loadMenusTheoKhungGio();
    _loadAllMonAns();
    _loadCategories();
    
    // Timer countdown
    _startCountdown();
  }

  void _startCountdown() {
    if (_timeRemaining > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _timeRemaining > 0) {
          setState(() {
            _timeRemaining--;
          });
          _startCountdown();
        }
      });
    }
  }

  Future<void> _loadMenusTheoKhungGio() async {
    setState(() => _loadingKhungGio = true);
    try {
      final menus = await _menuService.fetchMenusTheoKhungGio();
      setState(() {
        _menusTheoKhungGio = menus;
        _loadingKhungGio = false;
        // Giả sử API trả về thông tin khung giờ
        _khungGioHienTai = 'TRUA';
        _tenKhungGio = 'Trưa';
        _timeRemaining = 3600; // 1 giờ
      });
    } catch (e) {
      setState(() => _loadingKhungGio = false);
    }
  }

  Future<void> _loadAllMonAns() async {
    setState(() => _loadingAllMon = true);
    try {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      await viewModel.fetchInitialData();
      setState(() {
        _allMonAns = viewModel.monAns;
        _loadingAllMon = false;
      });
    } catch (e) {
      setState(() => _loadingAllMon = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      await viewModel.fetchInitialData();
      setState(() {
        _categories = viewModel.danhMucs.map((dm) => dm.tenDanhMuc).toList();
      });
    } catch (e) {
      // Ignore
    }
  }

  List<MonAn> get _filteredMonAns {
    var filtered = _allMonAns;
    
    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      final category = viewModel.danhMucs.firstWhere(
        (dm) => dm.tenDanhMuc == _selectedCategory,
        orElse: () => viewModel.danhMucs.first,
      );
      filtered = filtered.where((m) => m.maDanhMuc == category.maDanhMuc).toList();
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

  String _getKhungGioIcon(String? khungGio) {
    switch (khungGio) {
      case 'SANG':
        return '🌅';
      case 'TRUA':
        return '☀️';
      case 'CHIEU':
        return '🌆';
      case 'TOI':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Menu theo khung giờ'),
            Tab(text: 'Thực đơn điện tử'),
            Tab(text: 'Tất cả món'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTheoKhungGio(),
          _buildEMenuView(),
          _buildAllMonView(),
        ],
      ),
    );
  }

  Widget _buildMenuTheoKhungGio() {
    if (_loadingKhungGio) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMenusTheoKhungGio,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header với thông tin khung giờ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade600, Colors.purple.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getKhungGioIcon(_khungGioHienTai),
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu $_tenKhungGio',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Menu sẽ tự động thay đổi theo khung giờ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Còn lại trong khung giờ này:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo.shade100,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_timeRemaining),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(),
            const SizedBox(height: 24),
            
            // Danh sách menu
            if (_menusTheoKhungGio.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có menu nào cho khung giờ $_tenKhungGio',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _menusTheoKhungGio.length,
                itemBuilder: (context, index) {
                  final menu = _menusTheoKhungGio[index];
                  return _buildMenuCard(menu, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEMenuView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Thực đơn điện tử',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tính năng đang được phát triển',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
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
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _paginatedMonAns.length,
                            itemBuilder: (context, index) {
                              final monAn = _paginatedMonAns[index];
                              return _buildMonAnCard(monAn, index);
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
      selectedColor: Colors.indigo.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMenuDetail(menu),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_menu, size: 40),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant_menu, size: 40),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menu.tenMenu,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (menu.loaiMenu != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              menu.loaiMenu!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (menu.giaMenu != null) ...[
                      if (menu.giaGoc != null && menu.giaGoc! > menu.giaMenu!)
                        Row(
                          children: [
                            Text(
                              NumberFormat("#,###").format(menu.giaGoc!.toInt()),
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (menu.phanTramGiamGia != null && menu.phanTramGiamGia! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${menu.phanTramGiamGia!.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      Text(
                        '${NumberFormat("#,###").format(menu.giaMenu!.toInt())} đ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ],
                    if (menu.chiTietMenus != null && menu.chiTietMenus!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${menu.chiTietMenus!.length} món trong menu',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
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
    final imageUrl = monAn.hinhAnhMonAns.isNotEmpty
        ? '${ApiConstants.imageBaseUrl}/${monAn.hinhAnhMonAns.first.urlHinhAnh}'
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMonAnDetail(monAn),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_menu, size: 40),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant_menu, size: 40),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monAn.tenMonAn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${NumberFormat("#,###").format(monAn.gia)} đ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
                      ),
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy món nào phù hợp với "$_searchQuery"'
                : _selectedCategory != null
                    ? 'Chưa có món nào trong danh mục "$_selectedCategory"'
                    : 'Chưa có món nào trong thực đơn',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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
    final imageUrl = monAn.hinhAnhMonAns.isNotEmpty
        ? '${ApiConstants.imageBaseUrl}/${monAn.hinhAnhMonAns.first.urlHinhAnh}'
        : null;

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
                    Text(
                      'Giá: ${NumberFormat("#,###").format(monAn.gia)} đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
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
  }
}
