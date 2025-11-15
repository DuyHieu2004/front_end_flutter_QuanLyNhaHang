import 'package:flutter/material.dart';
import 'package:front_end_app/services/ban_an_service.dart';
import 'package:front_end_app/utils/QuickAlert.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ban_an.dart';

import 'dat_ban_form_screen.dart'; // Import form đặt bàn

class DatBanScreen extends StatefulWidget {
  const DatBanScreen({Key? key}) : super(key: key);

  @override
  State<DatBanScreen> createState() => _DatBanScreenState();
}

class _DatBanScreenState extends State<DatBanScreen> {
  late Future<List<BanAn>> _banAnFuture;

  final _banAnService = BanAnService();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  int _selectedSoNguoi = 2;
  // Giả lập ID khách hàng (Thực tế bạn lấy từ SharedPreferences/Token sau khi Login)
  String? _currentUserId;

  // == QUAN TRỌNG: Dùng Set để hỗ trợ chọn nhiều bàn (Gộp bàn) ==
  final Set<String> _selectedTableIds = {};
  final List<BanAn> _selectedTablesList = [];
  String _selectedTang = "Tất cả";

  // Danh sách các tầng (Có thể hardcode hoặc lấy từ API)
  final List<String> _listTang = ["Tất cả", "Tầng trệt", "Tầng 1", "Tầng 2"];

  void _debugCheckStorage() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== KIỂM TRA BỘ NHỚ MÁY ===");
    print("Keys hiện có: ${prefs.getKeys()}");
    print("MaKhachHang: ${prefs.getString('maKhachHang')}");
    print("HoTen: ${prefs.getString('hoTen')}");
    print("Email: ${prefs.getString('email')}");
    print("===========================");
  }

  @override
  void initState() {
    super.initState();
   _initData();
   _debugCheckStorage();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lấy mã khách hàng đã lưu lúc đăng nhập.
      // Nếu chưa đăng nhập thì nó trả về null (hoặc bạn gán mặc định "")
      _currentUserId = prefs.getString('maKhachHang') ?? "";

      // Sau khi có ID rồi mới tải danh sách bàn
      _loadFilteredTables();
    });

    // Debug xem lấy được chưa
    print("User ID hiện tại: $_currentUserId");
  }

  void _loadFilteredTables() {
    // Nếu chưa lấy được ID người dùng thì khoan hãy gọi (tránh lỗi logic)
    if (_currentUserId == null) return;

    setState(() {
      _banAnFuture = _banAnService.fetchAvailableTables(
          _selectedDateTime,
          _selectedSoNguoi,
          _currentUserId! // <--- TRUYỀN CÁI ID NÀY VÀO NÈ!
      );

      // Clear các bàn đang chọn để tránh lỗi
      _selectedTableIds.clear();
      _selectedTablesList.clear();
    });
  }


  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _loadFilteredTables();
  }

  // Hàm chọn Số người
  Future<void> _pickSoNguoi() async {
    int? selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn số người'),
        children: List.generate(10, (index) {
          int soNguoi = index + 1;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, soNguoi),
            child: Text('$soNguoi người'),
          );
        }),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedSoNguoi = selected;
      });
      // Tải lại bàn sau khi chọn
      _loadFilteredTables();
    }
  }

  Color _getColorForStatus(String? tenTrangThai, bool isSelected) {
    if (isSelected) return Colors.blueAccent; // Đang chọn luôn là màu xanh

    switch (tenTrangThai) {
      case 'Trong':
        return Colors.green;        // 🟢 1. Trống
      case 'CanGhep':
        return Colors.orange;       // 🟠 2. Cần ghép
      case 'CuaTui':
        return Colors.purpleAccent; // 🟣 3. Bàn của mình
      case 'DaDat':
        return Colors.red.shade200; // 🔴 4. Người khác đặt
      case 'BaoTri':
        return Colors.grey;         // ⚫ 5. Hỏng
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm & Đặt Bàn'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Gọi widget bộ lọc mới

          Expanded(
            child: FutureBuilder<List<BanAn>>(
              future: _banAnFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi kết nối: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không tìm thấy dữ liệu bàn.'));
                }

                // === LOGIC LỌC TẦNG TẠI ĐÂY ===
                // 1. Lấy tất cả bàn từ API
                final allBanAns = snapshot.data!;

                // 2. Lọc theo tầng đang chọn
                List<BanAn> displayBanAns = allBanAns;
                if (_selectedTang != "Tất cả") {
                  // So sánh tên tầng (API trả về trong trường tenTang)
                  displayBanAns = allBanAns.where((b) => b.tenTang == _selectedTang).toList();
                }

                if (displayBanAns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 50, color: Colors.grey),
                        Text('Không có bàn nào ở $_selectedTang', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 3. Hiển thị Grid
                return RefreshIndicator(
                  onRefresh: () async => _loadFilteredTables(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: displayBanAns.length,
                    itemBuilder: (context, index) {
                      final banAn = displayBanAns[index];
                      return _buildTableCard(context, banAn);
                    },
                  ),
                );
              },
            ),
          ),
          _buildLegend(),
        ],
      ),
      // Nút đặt bàn nổi
      floatingActionButton: _selectedTableIds.isNotEmpty
          ? FloatingActionButton.extended(
        label: const Text("Đặt bàn"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          // 1. Kiểm tra: Nếu chưa chọn bàn nào thì báo lỗi
          if (_selectedTablesList.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vui lòng chọn ít nhất một bàn để tiếp tục!"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // 2. Chuyển sang màn hình Form và CHỜ kết quả trả về (dùng await)
          final bool? ketQuaDatBan = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatBanFormScreen(
                // Truyền danh sách bàn sang form
                danhSachBan: List.from(_selectedTablesList),
              ),
            ),
          );

          // 3. Kiểm tra kết quả: Nếu đặt thành công (trả về true) thì tải lại dữ liệu
          if (ketQuaDatBan == true) {
            print("--- Đã đặt bàn xong, đang tải lại danh sách bàn ---");

            // Gọi hàm này để API chạy lại -> Cập nhật màu bàn từ "Trống" sang "Của bạn"
            _loadFilteredTables();

            // Hiện thông báo nhỏ bên dưới
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cập nhật trạng thái bàn thành công!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      )
          : null,
    );
  }

// --- 3. WIDGET THANH LỌC (ĐÃ SỬA ĐỂ GỌI CÁC HÀM Ở TRÊN) ---
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // HÀNG 1: NGÀY & GIỜ
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDateTime, // <--- GỌI HÀM CỦA BẠN Ở ĐÂY
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(DateFormat('dd/MM/yyyy').format(_selectedDateTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickDateTime, // <--- GỌI HÀM CỦA BẠN Ở ĐÂY (Chọn giờ chung logic)
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(DateFormat('HH:mm').format(_selectedDateTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // HÀNG 2: SỐ NGƯỜI & TẦNG
          Row(
            children: [
              InkWell(
                onTap: _pickSoNguoi, // <--- GỌI HÀM CỦA BẠN Ở ĐÂY
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text("$_selectedSoNguoi người", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Dropdown chọn Tầng
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTang,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 15),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTang = newValue;
                            // Reset chọn khi đổi tầng
                            _selectedTableIds.clear();
                            _selectedTablesList.clear();
                          });
                        }
                      },
                      items: _listTang.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.deepPurple),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }


  Widget _buildTableCard(BuildContext context, BanAn banAn) {
    final isSelected = _selectedTableIds.contains(banAn.maBan);
    final status = banAn.tenTrangThai;
    final color = _getColorForStatus(status, isSelected);

    return GestureDetector(
      onTap: () {
        switch (status) {
        // NHÓM 1: CHO PHÉP CHỌN (Trống & Cần ghép)
          case 'Trong':
          case 'CanGhep':
            setState(() {
              if (isSelected) {
                _selectedTableIds.remove(banAn.maBan);
                _selectedTablesList.removeWhere((b) => b.maBan == banAn.maBan);
              } else {
                _selectedTableIds.add(banAn.maBan!);
                _selectedTablesList.add(banAn);
              }
            });
            break;

        // NHÓM 2: XEM CHI TIẾT (Bàn của tui)
          case 'CuaTui':
            _showMyBookingDetail(banAn.maBan!);
            break;

        // NHÓM 3: CHẶN (Đã đặt / Bảo trì)
          case 'DaDat':
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Bàn này đã được người khác đặt!'), duration: Duration(milliseconds: 800)));
            break;
          case 'BaoTri':
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Bàn đang bảo trì.'), duration: Duration(milliseconds: 800)));
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color, width: isSelected ? 3 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_rounded, size: 30.0, color: color),
            const SizedBox(height: 4.0),
            Text(banAn.tenBan ?? "", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text('${banAn.sucChua} ghế', style: const TextStyle(fontSize: 12)),

            // Hiển thị nhãn phụ
            if (status == 'CuaTui')
              const Text('(Của bạn)', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
            if (status == 'CanGhep')
              const Text('(Ghép bàn)', style: TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  void _showMyBookingDetail(String maBan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await _banAnService.getMyBookingDetail(maBan, _selectedDateTime);      Navigator.pop(context); // Tắt loading

      // Parse dữ liệu sơ bộ từ JSON (Hoặc dùng Model nếu bạn đã tạo)
      final List<dynamic> monAns = detail['monAns'] ?? [];
      final String trangThai = detail['trangThai'] ?? '';
      final int soNguoi = detail['soNguoi'] ?? 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chi tiết đặt bàn'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Trạng thái: $trangThai', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Số người: $soNguoi'),
                const Divider(),
                const Text('Món ăn:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...monAns.map((m) => Text('- ${m['tenMon']} (x${m['soLuong']})')),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }


  // == HÀM XÁC NHẬN ĐẶT BÀN (GỘP BÀN) ==
  void _onConfirmBooking() {
    // Tính tổng sức chứa
    int totalSeats = _selectedTablesList.fold(0, (sum, item) => sum + (item.sucChua ?? 0));

    if (totalSeats < _selectedSoNguoi) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Chưa đủ chỗ"),
          content: Text("Bạn đi $_selectedSoNguoi người nhưng các bàn đã chọn chỉ chứa được $totalSeats người. Bạn có muốn chọn thêm không?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Chọn thêm")),
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              _navigateToForm(); // Vẫn cho đặt
            }, child: const Text("Vẫn đặt", style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    } else {
      _navigateToForm();
    }
  }

  void _navigateToForm() {
    // Kiểm tra rỗng
    if (_selectedTablesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 bàn!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatBanFormScreen(
          // SỬA CHỖ NÀY: Truyền list bàn đã chọn qua
          danhSachBan: _selectedTablesList,
        ),
      ),
    ).then((result) {
      // Khi quay lại (đặt thành công), refresh lại màn hình
      if (result == true) {
        _loadFilteredTables();
      }
    });
  }


  // == 11. Cập nhật Chú thích ==
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
        child: Wrap(
            spacing: 8.0,
            children: [
              _buildLegendItem(Colors.green, 'Trống'),
              _buildLegendItem(Colors.orange, 'Ghép'),
              _buildLegendItem(Colors.purpleAccent, 'Của bạn'),
              _buildLegendItem(Colors.red.shade200, 'Đã đặt'),
            ]
        )
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.black54, width: 0.5),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(text, style: const TextStyle(fontSize: 14.0)),
      ],
    );
  }
}