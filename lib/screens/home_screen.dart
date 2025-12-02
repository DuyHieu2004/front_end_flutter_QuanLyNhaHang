import 'package:flutter/material.dart';
import 'package:front_end_app/screens/dat_ban_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/menu_view_model.dart';
import '../models/danh_muc.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chủ"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer: const _HomeDrawer(),
      body: const _HomeContent(),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Nhà hàng Việt",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Trang chủ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Đặt bàn'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DatBanScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Thực đơn'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<MenuViewModel>(context, listen: false)
            .fetchInitialData();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(colorScheme: colorScheme),
                const SizedBox(height: 16),
                _MenuSectionTitle(colorScheme: colorScheme),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _SpecialMenuList(),
            ),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HeroSection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/splash2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Trải Nghiệm Tinh Hoa\nẨm Thực Việt",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Khám phá hương vị truyền thống\ntrong không gian sang trọng, ấm cúng.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DatBanScreen()),
                        );
                      },
                      child: const Text(
                        "Đặt bàn ngay",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Điều hướng tới màn hình thực đơn chi tiết
                      },
                      child: const Text(
                        "Xem thực đơn",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final ColorScheme colorScheme;

  const _MenuSectionTitle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Menu đặc biệt",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Một vài gợi ý cho hôm nay",
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // TODO: Điều hướng tới màn hình danh sách thực đơn đầy đủ
            },
            child: const Text("Xem tất cả"),
          )
        ],
      ),
    );
  }
}

class _SpecialMenuList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MenuViewModel>(
      builder: (context, vm, _) {
        // Sử dụng danh mục (Menu) từ API thay vì danh sách món ăn
        if (vm.isLoading && vm.danhMucs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.danhMucs.isEmpty) {
          return const Center(
            child: Text(
              "Hiện tại chưa có menu nào.",
              style: TextStyle(fontSize: 14),
            ),
          );
        }

        final List<DanhMuc> items =
            vm.danhMucs.length > 6 ? vm.danhMucs.take(6).toList() : vm.danhMucs;

        // Hiển thị menu đặc biệt theo dạng GridView 2 cột
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 1.1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final danhMuc = items[index];
            return _MenuCard(danhMuc: danhMuc);
          },
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final DanhMuc danhMuc;

  const _MenuCard({required this.danhMuc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 40,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  danhMuc.tenDanhMuc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}