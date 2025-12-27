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
  
  // --- COLOR PALETTE (MÀU SẮC MỚI) ---
  final Color _wineRed = const Color(0xFF800020); // Đỏ rượu vang
  final Color _lightWine = const Color(0xFFA52A2A); // Đỏ nhạt
  final Color _bgWhite = const Color(0xFFFAFAFA); // Nền trắng ngà

  // --- CÁC BIẾN LOGIC (GIỮ NGUYÊN) ---
  String _searchQuery = '';
  String _sortBy = 'name';
  String? _selectedCategory;
  
  List<Menu> _menusDangApDung = [];
  bool _loadingMenusDangApDung = false;
  
  List<MonAn> _monAnsTheoDanhMuc = [];
  List<DanhMuc> _danhMucsEMenu = [];
  bool _loadingEMenu = false;
  String? _selectedEMenuCategory;
  
  List<MonAn> _allMonAns = [];
  bool _loadingAllMon = false;
  List<String> _categories = [];
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMenusDangApDung();
    _loadAllMonAns();
    _loadCategories();
    _loadEMenuData();
  }

  // --- PHẦN LOGIC DATA (GIỮ NGUYÊN) ---

  Future<void> _loadMenusDangApDung() async {
    setState(() => _loadingMenusDangApDung = true);
    try {
      final menus = await _menuService.fetchMenusDangApDung();
      setState(() {
        _menusDangApDung = menus ?? [];
        _loadingMenusDangApDung = false;
      });
    } catch (e) {
      setState(() {
        _menusDangApDung = [];
        _loadingMenusDangApDung = false;
      });
    }
  }

  Future<void> _loadEMenuData() async {
    setState(() => _loadingEMenu = true);
    try {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      await viewModel.fetchInitialData();
      setState(() {
        _monAnsTheoDanhMuc = viewModel.monAns ?? [];
        _danhMucsEMenu = viewModel.danhMucs ?? [];
        _loadingEMenu = false;
      });
    } catch (e) {
      setState(() {
        _monAnsTheoDanhMuc = [];
        _danhMucsEMenu = [];
        _loadingEMenu = false;
      });
    }
  }

  String _getTenDanhMuc(String maDanhMuc) {
    if (_danhMucsEMenu.isEmpty) return 'Khác';
    final danhMuc = _danhMucsEMenu.firstWhere(
      (dm) => dm.maDanhMuc == maDanhMuc,
      orElse: () => DanhMuc(maDanhMuc: maDanhMuc, tenDanhMuc: 'Khác'),
    );
    return danhMuc.tenDanhMuc;
  }

  Future<void> _loadAllMonAns() async {
    setState(() => _loadingAllMon = true);
    try {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      await viewModel.fetchInitialData();
      setState(() {
        _allMonAns = viewModel.monAns ?? [];
        _loadingAllMon = false;
      });
    } catch (e) {
      setState(() {
        _allMonAns = [];
        _loadingAllMon = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final viewModel = Provider.of<MenuViewModel>(context, listen: false);
      await viewModel.fetchInitialData();
      setState(() {
        _categories = viewModel.danhMucs?.map((dm) => dm.tenDanhMuc).toList() ?? [];
      });
    } catch (e) {
      setState(() {
        _categories = [];
      });
    }
  }

  List<MonAn> get _filteredMonAns {
    var filtered = _allMonAns;
    
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
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.tenMonAn.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
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
    if (start >= _filteredMonAns.length) return [];
    return _filteredMonAns.sublist(
      start,
      end > _filteredMonAns.length ? _filteredMonAns.length : end,
    );
  }

  int get _totalPages => (_filteredMonAns.length / _itemsPerPage).ceil();

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- PHẦN GIAO DIỆN MỚI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'THỰC ĐƠN',
          style: TextStyle(
            color: _wineRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _wineRed,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: _wineRed.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'Combo Menu'),
                Tab(text: 'E-Menu'),
                Tab(text: 'Tất cả'),
              ],
            ),
          ),
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
      return Center(child: CircularProgressIndicator(color: _wineRed));
    }

    return RefreshIndicator(
      color: _wineRed,
      onRefresh: _loadMenusDangApDung,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_wineRed, _lightWine],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _wineRed.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, size: 32, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu Ưu Đãi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Các combo đang được áp dụng',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            if (_menusDangApDung.isEmpty)
              _buildEmptyState('Chưa có menu nào đang áp dụng')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: _menusDangApDung.length,
                itemBuilder: (context, index) {
                  return _buildMenuCard(_menusDangApDung[index], index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEMenuView() {
    if (_loadingEMenu) {
      return Center(child: CircularProgressIndicator(color: _wineRed));
    }

    List<MonAn> filteredMonAns = _monAnsTheoDanhMuc;
    if (_selectedEMenuCategory != null && _selectedEMenuCategory!.isNotEmpty) {
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

    Map<String, List<MonAn>> monAnsByCategory = {};
    for (var monAn in filteredMonAns) {
      String category = _getTenDanhMuc(monAn.maDanhMuc);
      if (!monAnsByCategory.containsKey(category)) {
        monAnsByCategory[category] = [];
      }
      monAnsByCategory[category]!.add(monAn);
    }

    return RefreshIndicator(
      color: _wineRed,
      onRefresh: _loadEMenuData,
      child: Column(
        children: [
          if (_danhMucsEMenu.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('Tất cả', null, isEMenu: true),
                  const SizedBox(width: 8),
                  ..._danhMucsEMenu.map((dm) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(dm.tenDanhMuc, dm.tenDanhMuc, isEMenu: true),
                  )),
                ],
              ),
            ),
          
          Expanded(
            child: monAnsByCategory.isEmpty
                ? _buildEmptyState('Chưa có món ăn nào')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: monAnsByCategory.length,
                    itemBuilder: (context, categoryIndex) {
                      final category = monAnsByCategory.keys.elementAt(categoryIndex);
                      final monAns = monAnsByCategory[category]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 12, top: categoryIndex > 0 ? 24 : 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _wineRed,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: _wineRed,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '(${monAns.length})',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: monAns.length,
                            itemBuilder: (context, index) {
                              return _buildMonAnCard(monAns[index], index);
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

  Widget _buildAllMonView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món ăn...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: _wineRed),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _wineRed.withOpacity(0.5), width: 1),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                },
              ),
              
              if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            Chip(
                              label: Text('Tìm: "$_searchQuery"'),
                              backgroundColor: _wineRed.withOpacity(0.1),
                              labelStyle: TextStyle(color: _wineRed, fontSize: 12),
                              deleteIconColor: _wineRed,
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
                              label: Text('Mục: $_selectedCategory'),
                              backgroundColor: _wineRed.withOpacity(0.1),
                              labelStyle: TextStyle(color: _wineRed, fontSize: 12),
                              deleteIconColor: _wineRed,
                              onDeleted: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _currentPage = 1;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: Icon(Icons.sort, color: _wineRed, size: 20),
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
                            DropdownMenuItem(value: 'price-asc', child: Text('Giá tăng')),
                            DropdownMenuItem(value: 'price-desc', child: Text('Giá giảm')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value ?? 'name';
                              _currentPage = 1;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        if (_categories.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Tất cả', null, isEMenu: false),
                const SizedBox(width: 8),
                ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(cat, cat, isEMenu: false),
                )),
              ],
            ),
          ),
        
        Expanded(
          child: _loadingAllMon
              ? _buildShimmerGrid()
              : _filteredMonAns.isEmpty
                  ? _buildEmptyState('Không tìm thấy món ăn')
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _paginatedMonAns.length,
                            itemBuilder: (context, index) {
                              return _buildMonAnCard(_paginatedMonAns[index], index);
                            },
                          ),
                        ),
                        if (_totalPages > 1) _buildPagination(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, {required bool isEMenu}) {
    final currentSelected = isEMenu ? _selectedEMenuCategory : _selectedCategory;
    final isSelected = currentSelected == value;
    
    return Center(
      child: InkWell(
        onTap: () {
          setState(() {
            if (isEMenu) {
              _selectedEMenuCategory = isSelected ? null : value;
            } else {
              _selectedCategory = isSelected ? null : value;
              _currentPage = 1;
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _wineRed : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _wineRed : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: isSelected
              ? [BoxShadow(color: _wineRed.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
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

    return GestureDetector(
      onTap: () => _showMenuDetail(menu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  if (menu.phanTramGiamGia != null && menu.phanTramGiamGia! > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _wineRed,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(12),
                          ),
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
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.tenMenu,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menu.chiTietMenus != null 
                              ? '${menu.chiTietMenus!.length} món' 
                              : 'Combo',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (menu.giaGoc != null && menu.giaGoc! > menu.giaMenu!)
                                Text(
                                  '${NumberFormat("#,###").format(menu.giaGoc!.toInt())} đ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade400
                                  ),
                                ),
                              Text(
                                '${NumberFormat("#,###").format(menu.giaMenu!.toInt())} đ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _wineRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _wineRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add, size: 18, color: _wineRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildMonAnCard(MonAn monAn, int index) {
    final imageUrl = monAn.hinhAnhMonAns.isNotEmpty
        ? '${ApiConstants.imageBaseUrl}/${monAn.hinhAnhMonAns.first.urlHinhAnh}'
        : null;

    return GestureDetector(
      onTap: () => _showMonAnDetail(monAn),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monAn.tenMonAn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monAn.tenDanhMuc ?? _getTenDanhMuc(monAn.maDanhMuc),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (monAn.phienBanMonAns.isNotEmpty)
                          Expanded(
                            child: Text(
                              'Từ ${NumberFormat("#,###").format(monAn.phienBanMonAns.first.gia.toInt())} đ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _wineRed),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else if (monAn.gia > 0)
                          Text(
                            '${NumberFormat("#,###").format(monAn.gia.toInt())} đ',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _wineRed),
                          )
                        else
                          Text(
                            'Liên hệ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _wineRed),
                          ),
                        if (monAn.gia > 0 || monAn.phienBanMonAns.isNotEmpty)
                          Icon(Icons.add_circle, color: _wineRed, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.restaurant, color: Colors.grey.shade300, size: 40),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
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
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            icon: Icon(Icons.chevron_left, color: _currentPage > 1 ? _wineRed : Colors.grey),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _wineRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_currentPage / $_totalPages',
              style: TextStyle(fontWeight: FontWeight.bold, color: _wineRed),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
            icon: Icon(Icons.chevron_right, color: _currentPage < _totalPages ? _wineRed : Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- DETAIL MODALS (BOTTOM SHEETS) ---

  void _showMenuDetail(Menu menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Detail Header Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: menu.hinhAnh != null
                      ? Image.network(
                          menu.hinhAnh!.startsWith('http')
                              ? menu.hinhAnh!
                              : '${ApiConstants.imageBaseUrl}${menu.hinhAnh!.startsWith('/') ? '' : '/'}${menu.hinhAnh}',
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(height: 250, color: Colors.grey.shade200),
                        )
                      : Container(height: 250, color: Colors.grey.shade200),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            
            // Info Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.tenMenu,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${NumberFormat("#,###").format(menu.giaMenu!.toInt())} đ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _wineRed),
                        ),
                        if (menu.giaGoc != null && menu.giaGoc! > menu.giaMenu!)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              '${NumberFormat("#,###").format(menu.giaGoc!.toInt())} đ',
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade400
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    if (menu.moTa != null && menu.moTa!.isNotEmpty) ...[
                      const Text('Mô tả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(menu.moTa!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                      const SizedBox(height: 24),
                    ],
                    
                    if (menu.chiTietMenus != null && menu.chiTietMenus!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: _wineRed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Chi tiết (${menu.chiTietMenus!.length} món)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...menu.chiTietMenus!.map((ct) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: _wineRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ct.monAn?.tenMonAn ?? 'Món ăn',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('x${ct.soLuong}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            
            // Add to Cart Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add cart logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wineRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_shopping_cart),
                    SizedBox(width: 8),
                    Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(height: 250, color: Colors.grey.shade200),
                ),
              ),
              
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monAn.tenMonAn,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    if (monAn.phienBanMonAns.isNotEmpty)
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                            '${NumberFormat("#,###").format(monAn.phienBanMonAns.first.gia.toInt())} đ',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _wineRed),
                           ),
                           const SizedBox(height: 4),
                           Text('Giá thay đổi tùy size', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                         ],
                       )
                    else
                      Text(
                        '${NumberFormat("#,###").format(monAn.gia.toInt())} đ',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _wineRed),
                      ),
                      
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                   // TODO: Add logic select details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wineRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant),
                    SizedBox(width: 8),
                    Text('Chọn món', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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