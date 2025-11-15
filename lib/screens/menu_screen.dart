import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/menu_view_model.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final viewModel = Provider.of<MenuViewModel>(context, listen: false);
    final serverUrl = 'https://192.168.1.236:7190';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn Nhà hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => viewModel.search(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
              ),
            ),
          ),

          Consumer<MenuViewModel>(
            builder: (context, vm, child) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: vm.danhMucs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text('Tất cả'),
                          selected: vm.selectedMaDanhMuc == null,
                          onSelected: (selected) => vm.selectCategory(null),
                        ),
                      );
                    }
                    final category = vm.danhMucs[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category.tenDanhMuc),
                        selected: vm.selectedMaDanhMuc == category.maDanhMuc,
                        onSelected: (selected) => vm.selectCategory(category.maDanhMuc),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          Expanded(
            child: Consumer<MenuViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.monAns.isEmpty) {
                  return const Center(child: Text("Không tìm thấy món ăn nào."));
                }

                final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: vm.monAns.length,
                  itemBuilder: (context, index) {
                    final monAn = vm.monAns[index];
                    final imageUrl = monAn.hinhAnhMonAns.isNotEmpty
                        ? '$serverUrl/${monAn.hinhAnhMonAns.first.urlHinhAnh}'
                        : 'https://via.placeholder.com/150';

                    return Card(
                      elevation: 4,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.error)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(monAn.tenMonAn, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis,),
                                Text(formatCurrency.format(monAn.gia), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}