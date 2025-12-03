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
  
  // Lưu danh sách bàn hiện tại để dùng trong _showMyBookingDetail
  List<BanAn> _currentTablesList = [];

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

    if (tenTrangThai == null) return Colors.grey;
    
    // Chuẩn hóa trạng thái (giống web khách hàng)
    final status = tenTrangThai.toLowerCase().trim();
    
    // Trạng thái "Đang trống" hoặc "Trống" → màu xanh (có thể đặt)
    if (status == 'đang trống' || 
        status == 'trống' || 
        status == 'trong' ||
        status == 'available' ||
        status == 'empty') {
      return Colors.green;
    }
    
    // Trạng thái "Không đủ sức chứa" hoặc "Cần ghép" → màu cam (có thể chọn nhiều bàn)
    if (status.contains('không đủ') || 
        status.contains('cần ghép') ||
        status.contains('sức chứa nhỏ') ||
        status == 'canghep' ||
        status == 'suc chua nho') {
      return Colors.orange;
    }
    
    // Trạng thái "Của tôi" hoặc "Bàn của bạn" → màu tím (xem chi tiết)
    if (status.contains('của tôi') || 
        status.contains('của bạn') ||
        status == 'cuatui' ||
        status == 'my table') {
      return Colors.purpleAccent;
    }
    
    // Trạng thái "Đã đặt" → màu đỏ (không chọn được)
    if (status.contains('đã đặt') || 
        status.contains('đã được đặt') ||
        status == 'dadat' ||
        status == 'booked' ||
        status == 'occupied') {
      return Colors.red.shade200;
    }
    
    // Trạng thái "Bảo trì" → màu xám (không chọn được)
    if (status.contains('bảo trì') || 
        status == 'baotri' ||
        status == 'maintenance') {
      return Colors.grey;
    }
    
    // Mặc định
    return Colors.grey;
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
                
                // Lưu danh sách bàn để dùng trong _showMyBookingDetail
                _currentTablesList = allBanAns;

                // 2. Lọc theo trạng thái (chỉ hiển thị 2 trạng thái như web khách hàng)
                // API GetStatusByTime đã tự động kiểm tra hóa đơn trong thời gian được chọn
                // - Nếu bàn có hóa đơn trong thời gian đó → trạng thái "Đã đặt" → không hiển thị
                // - Nếu bàn không có hóa đơn → trạng thái "Đang trống" hoặc "Không đủ sức chứa" → hiển thị
                List<BanAn> filteredByStatus = allBanAns.where((b) {
                  final status = (b.tenTrangThai ?? '').toLowerCase().trim();
                  
                  // Loại bỏ các bàn đã được đặt (giống web khách hàng)
                  if (status.contains('đã đặt') || 
                      status.contains('đã được đặt') ||
                      status == 'dadat' ||
                      status == 'booked' ||
                      status == 'occupied') {
                    return false; // Không hiển thị bàn đã đặt
                  }
                  
                  // Chỉ hiển thị: "Đang trống" và "Không đủ sức chứa" (có thể chọn)
                  return status == 'đang trống' || 
                         status == 'trống' || 
                         status == 'trong' ||
                         status == 'available' ||
                         status == 'empty' ||
                         status.contains('không đủ') ||
                         status.contains('cần ghép') ||
                         status.contains('sức chứa nhỏ') ||
                         status == 'canghep' ||
                         status == 'suc chua nho';
                }).toList();

                // 3. Lọc theo tầng đang chọn
                List<BanAn> displayBanAns = filteredByStatus;
                if (_selectedTang != "Tất cả") {
                  // So sánh tên tầng (API trả về trong trường tenTang)
                  displayBanAns = filteredByStatus.where((b) => b.tenTang == _selectedTang).toList();
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

                // Tính tổng sức chứa đã chọn
                final totalSelectedCapacity = _selectedTablesList.fold(
                  0, 
                  (sum, table) => sum + (table.sucChua ?? 0)
                );
                final remainingGuests = _selectedSoNguoi > 0 
                    ? (_selectedSoNguoi - totalSelectedCapacity).clamp(0, double.infinity).toInt()
                    : 0;
                final hasEnoughCapacity = _selectedTableIds.isNotEmpty && totalSelectedCapacity >= _selectedSoNguoi;

                // 3. Hiển thị Grid
                return RefreshIndicator(
                  onRefresh: () async => _loadFilteredTables(),
                  child: Column(
                    children: [
                      // Hiển thị thông tin tổng sức chứa đã chọn
                      if (_selectedTableIds.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasEnoughCapacity 
                                ? Colors.green.shade50 
                                : Colors.orange.shade50,
                            border: Border.all(
                              color: hasEnoughCapacity 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng sức chứa đã chọn: $totalSelectedCapacity / $_selectedSoNguoi khách',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedTableIds.isEmpty)
                                const Text(
                                  'Vui lòng chọn ít nhất một bàn để gửi yêu cầu đặt chỗ.',
                                  style: TextStyle(color: Colors.orange),
                                )
                              else if (remainingGuests > 0)
                                Text(
                                  'Còn thiếu $remainingGuests chỗ. Vui lòng chọn thêm bàn hoặc giảm số khách.',
                                  style: const TextStyle(color: Colors.orange),
                                )
                              else
                                const Text(
                                  'Đã đủ chỗ cho khách. Bạn vẫn có thể ghi chú thêm yêu cầu đặc biệt.',
                                  style: TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      Expanded(
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildLegend(),
        ],
      ),
      // Nút đặt bàn nổi với validation
      floatingActionButton: _selectedTableIds.isNotEmpty
          ? Builder(
              builder: (context) {
                final totalCapacity = _selectedTablesList.fold(
                  0, 
                  (sum, table) => sum + (table.sucChua ?? 0)
                );
                final remainingGuests = _selectedSoNguoi > 0 
                    ? (_selectedSoNguoi - totalCapacity).clamp(0, double.infinity).toInt()
                    : 0;
                final hasEnoughCapacity = totalCapacity >= _selectedSoNguoi;
                
                return FloatingActionButton.extended(
                  label: Text(hasEnoughCapacity ? "Đặt bàn" : "Thiếu $remainingGuests chỗ"),
                  icon: const Icon(Icons.check),
                  backgroundColor: hasEnoughCapacity ? Colors.deepPurple : Colors.orange,
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
                              
                              // 2. Kiểm tra đủ sức chứa
                              final totalCapacity = _selectedTablesList.fold(
                                0, 
                                (sum, table) => sum + (table.sucChua ?? 0)
                              );
                              final remainingGuests = _selectedSoNguoi > 0 
                                  ? (_selectedSoNguoi - totalCapacity).clamp(0, double.infinity).toInt()
                                  : 0;
                              
                              if (remainingGuests > 0) {
                                final shouldContinue = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Chưa đủ chỗ"),
                                    content: Text(
                                      "Bạn đi $_selectedSoNguoi người nhưng các bàn đã chọn chỉ chứa được $totalCapacity người.\n\n"
                                      "Còn thiếu $remainingGuests chỗ. Bạn có muốn tiếp tục đặt bàn không?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("Chọn thêm bàn"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text("Vẫn đặt", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldContinue != true) {
                                  return;
                                }
                              }

                              // 3. Chuyển sang màn hình Form và CHỜ kết quả trả về (dùng await)
                              final bool? ketQuaDatBan = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DatBanFormScreen(
                                    // Truyền danh sách bàn, số lượng người và thời gian sang form
                                    danhSachBan: List.from(_selectedTablesList),
                                    soNguoi: _selectedSoNguoi,
                                    thoiGian: _selectedDateTime,
                                  ),
                                ),
                              );

                              // 4. Kiểm tra kết quả: Nếu đặt thành công (trả về true) thì tải lại dữ liệu
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
                  );
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
        // Chuẩn hóa trạng thái (giống web khách hàng)
        final normalizedStatus = status?.toLowerCase().trim() ?? '';
        
        // NHÓM 1: CHO PHÉP CHỌN (Đang trống & Không đủ sức chứa)
        if (normalizedStatus == 'đang trống' || 
            normalizedStatus == 'trống' || 
            normalizedStatus == 'trong' ||
            normalizedStatus == 'available' ||
            normalizedStatus == 'empty' ||
            normalizedStatus.contains('không đủ') ||
            normalizedStatus.contains('cần ghép') ||
            normalizedStatus.contains('sức chứa nhỏ') ||
            normalizedStatus == 'canghep' ||
            normalizedStatus == 'suc chua nho') {
          setState(() {
            if (isSelected) {
              _selectedTableIds.remove(banAn.maBan);
              _selectedTablesList.removeWhere((b) => b.maBan == banAn.maBan);
            } else {
              _selectedTableIds.add(banAn.maBan);
              _selectedTablesList.add(banAn);
            }
          });
          return;
        }

        // NHÓM 2: XEM CHI TIẾT (Bàn của tôi)
        if (normalizedStatus.contains('của tôi') || 
            normalizedStatus.contains('của bạn') ||
            normalizedStatus == 'cuatui' ||
            normalizedStatus == 'my table') {
          _showMyBookingDetail(banAn.maBan);
          return;
        }

        // NHÓM 3: CHẶN (Đã đặt)
        if (normalizedStatus.contains('đã đặt') || 
            normalizedStatus.contains('đã được đặt') ||
            normalizedStatus == 'dadat' ||
            normalizedStatus == 'booked' ||
            normalizedStatus == 'occupied') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Bàn này đã được người khác đặt!'), 
              duration: Duration(milliseconds: 800)));
          return;
        }
        
        // NHÓM 4: CHẶN (Bảo trì)
        if (normalizedStatus.contains('bảo trì') || 
            normalizedStatus == 'baotri' ||
            normalizedStatus == 'maintenance') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Bàn đang bảo trì.'), 
              duration: Duration(milliseconds: 800)));
          return;
        }
        
        // Mặc định: không làm gì
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
            Builder(
              builder: (context) {
                if (status == null) return const SizedBox.shrink();
                final normalizedStatus = status.toLowerCase();
                if (normalizedStatus.contains('của tôi') || 
                    normalizedStatus.contains('của bạn') ||
                    normalizedStatus == 'cuatui') {
                  return const Text('(Của bạn)', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold));
                } else if (normalizedStatus.contains('không đủ') || 
                           normalizedStatus.contains('cần ghép') ||
                           normalizedStatus.contains('sức chứa nhỏ') ||
                           normalizedStatus == 'canghep') {
                  return const Text('(Ghép bàn)', style: TextStyle(fontSize: 10, color: Colors.orange));
                }
                return const SizedBox.shrink();
              },
            ),
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
      // Tìm bàn trong danh sách hiện tại để lấy maDonHang nếu có
      final foundBan = _currentTablesList.firstWhere(
        (b) => b.maBan == maBan,
        orElse: () => _currentTablesList.isNotEmpty ? _currentTablesList.first : BanAn(
          maBan: maBan,
          tenBan: '',
          sucChua: 0,
        ),
      );
      
      // Lấy chi tiết đơn hàng/hóa đơn
      final detail = await _banAnService.getMyBookingDetail(
        maDonHang: foundBan.maDonHang,
        maBan: maBan,
        selectedTime: _selectedDateTime,
      );
      
      Navigator.pop(context); // Tắt loading

      // Parse dữ liệu từ JSON (giống format web)
      final String maDonHang = detail['maDonHang'] ?? detail['MaDonHang'] ?? '';
      final String trangThai = detail['trangThai'] ?? detail['TrangThai'] ?? detail['tenTrangThai'] ?? '';
      final String tenTrangThai = detail['tenTrangThai'] ?? detail['TenTrangThai'] ?? trangThai;
      final int soNguoi = detail['soNguoi'] ?? detail['SoNguoi'] ?? 0;
      final double tongTien = (detail['tongTien'] ?? detail['TongTien'] ?? 0).toDouble();
      final String? thoiGianDatHang = detail['thoiGianDatHang'] ?? detail['ThoiGianDatHang'];
      final List<dynamic> monAns = detail['monAns'] ?? detail['MonAns'] ?? detail['chiTietDonHang'] ?? detail['ChiTietDonHang'] ?? [];
      final List<dynamic> danhSachBan = detail['danhSachBan'] ?? detail['DanhSachBan'] ?? detail['listMaBan'] ?? detail['ListMaBan'] ?? [];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Expanded(child: Text('Chi tiết đơn hàng')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mã đơn hàng
                if (maDonHang.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('Mã đơn: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(maDonHang, style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Trạng thái
                Row(
                  children: [
                    const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trangThai).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(trangThai)),
                      ),
                      child: Text(
                        tenTrangThai,
                        style: TextStyle(
                          color: _getStatusColor(trangThai),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Thông tin cơ bản
                if (thoiGianDatHang != null) ...[
                  Text('Thời gian đặt: ${_formatDateTime(thoiGianDatHang)}'),
                  const SizedBox(height: 4),
                ],
                Text('Số người: $soNguoi'),
                if (danhSachBan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Bàn: ${danhSachBan.join(", ")}'),
                ],
                
                const Divider(height: 24),
                
                // Danh sách món ăn
                const Text('Món ăn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (monAns.isEmpty)
                  const Text('Chưa có món nào', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  ...monAns.map((m) {
                    final tenMon = m['tenMon'] ?? m['TenMon'] ?? m['tenMonAn'] ?? m['TenMonAn'] ?? 'N/A';
                    final soLuong = m['soLuong'] ?? m['SoLuong'] ?? 0;
                    final donGia = (m['donGia'] ?? m['DonGia'] ?? 0).toDouble();
                    final thanhTien = soLuong * donGia;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tenMon, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('x$soLuong', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text(
                            '${_formatCurrency(thanhTien)} đ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                
                // Tổng tiền
                if (tongTien > 0) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${_formatCurrency(tongTien)} đ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String trangThai) {
    final status = trangThai.toUpperCase();
    if (status.contains('CHO_XAC_NHAN') || status.contains('CHỜ XÁC NHẬN')) {
      return Colors.orange;
    } else if (status.contains('DA_XAC_NHAN') || status.contains('ĐÃ XÁC NHẬN')) {
      return Colors.blue;
    } else if (status.contains('CHO_THANH_TOAN') || status.contains('CHỜ THANH TOÁN')) {
      return Colors.purple;
    } else if (status.contains('DA_HOAN_THANH') || status.contains('ĐÃ HOÀN THÀNH')) {
      return Colors.green;
    } else if (status.contains('DA_HUY') || status.contains('ĐÃ HỦY')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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
          // Truyền danh sách bàn, số lượng người và thời gian
          danhSachBan: _selectedTablesList,
          soNguoi: _selectedSoNguoi,
          thoiGian: _selectedDateTime,
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
        ],
      ),
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