import 'package:flutter/material.dart';
import 'package:front_end_app/providers/dat_ban_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // << Import providers
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ban_an.dart';
import '../models/dat_ban_dto.dart';

class DatBanFormScreen extends StatefulWidget {
  final List<BanAn> danhSachBan;

  const DatBanFormScreen({Key? key, required this.danhSachBan}) : super(key: key);

  @override
  State<DatBanFormScreen> createState() => _DatBanFormScreenState();
}

class _DatBanFormScreenState extends State<DatBanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenKhachController = TextEditingController();
  final _sdtController = TextEditingController();
  final _soNguoiController = TextEditingController();
  final _ghiChuController = TextEditingController();

  final _emailController = TextEditingController();
  late int _tongSucChua;
  late String _tenCacBan;

  @override
  void initState() {
    super.initState();
    _tinhToanThongTinBan();
    _autoFillUserData(); // Tự điền thông tin nếu có
    _debugCheckStorage(); // Kiểm tra bộ nhớ máy (debug)
  }

  void _debugCheckStorage() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== KIỂM TRA BỘ NHỚ MÁY ===");
    print("Keys hiện có: ${prefs.getKeys()}");
    print("MaKhachHang: ${prefs.getString('maKhachHang')}");
    print("HoTen: ${prefs.getString('hoTen')}");
    print("Email: ${prefs.getString('email')}");
    print("===========================");
  }

  // Hàm tính tổng sức chứa và tên các bàn
  void _tinhToanThongTinBan() {
    // Tính tổng sức chứa của tất cả các bàn được truyền qua
    _tongSucChua = widget.danhSachBan.fold(0, (sum, item) => sum + (item.sucChua ?? 0));

    // Nối tên các bàn lại (VD: "Bàn 1, Bàn 2")
    _tenCacBan = widget.danhSachBan.map((e) => e.tenBan).join(", ");
  }

  Future<void> _autoFillUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_tenKhachController.text.isEmpty) {
          _tenKhachController.text = prefs.getString('hoTen') ?? "";
        }
        if (_sdtController.text.isEmpty) {
          _sdtController.text = prefs.getString('soDienThoai') ?? "";
        }
        // 2. TỰ ĐỘNG ĐIỀN EMAIL (Nếu user đã đăng nhập và có email)
        if (_emailController.text.isEmpty) {
          _emailController.text = prefs.getString('email') ?? "";
        }
      });
    } catch (e) {
      print("Lỗi khi auto-fill data: $e");
    }
  }


  @override
  void dispose() {

    _tenKhachController.dispose();
    _sdtController.dispose();
    _soNguoiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  void _handleSubmit(DatBanProvider provider) async {
    print("--- Bắt đầu xử lý đặt bàn ---");

    try {
      if (!_formKey.currentState!.validate()) {
        print("Lỗi Validate Form");
        return;
      }

      // 3. LẤY THÔNG TIN TỪ SHAREDPREFERENCES NGAY LÚC SUBMIT
      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('maKhachHang'); // Lấy ID đã lưu

      // Nếu chuỗi rỗng thì coi như null (khách vãng lai)
      if (currentUserId != null && currentUserId.isEmpty) {
        currentUserId = null;
      }

      // Xử lý Email: Nếu người dùng không nhập gì thì gửi null
      String? emailToSend = _emailController.text.trim();
      if (emailToSend.isEmpty) {
        emailToSend = null;
      }

      String? maNhanVienHienTai = "NV002";

      final dto = DatBanDto(
        maBan: widget.danhSachBan.first.maBan,
        hoTenKhach: _tenKhachController.text,
        soDienThoaiKhach: _sdtController.text,
        thoiGianDatHang: provider.selectedDateTime,
        soLuongNguoi: int.parse(_soNguoiController.text),
        ghiChu: widget.danhSachBan.length > 1
            ? "Gộp bàn: $_tenCacBan. ${_ghiChuController.text}"
            : (_ghiChuController.text.isEmpty ? null : _ghiChuController.text),
        maNhanVien: maNhanVienHienTai,

        // 4. ĐIỀN DỮ LIỆU CHUẨN VÀO DTO
        maKhachHang: currentUserId, // ID lấy từ bộ nhớ
        email: emailToSend,         // Email lấy từ ô nhập liệu
        tienDatCoc: 0,              // Tạm thời = 0
      );

      print("DTO chuẩn bị gửi: ${dto.toJson()}");

      await provider.submitBooking(
        context: context,
        dto: dto,
        onSuccess: () {
          print("--- Đặt bàn thành công! ---");
          Navigator.of(context).pop(true);
        },
      );

    } catch (e, stackTrace) {
      print("🔴 LỖI NGHIÊM TRỌNG: $e");
      print(stackTrace);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Có lỗi xảy ra"),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatBanProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đặt Bàn: $_tenCacBan', style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Consumer<DatBanProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Text(
                        'Tổng sức chứa: $_tongSucChua người\n($_tenCacBan)',
                        style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _tenKhachController,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên khách hàng',
                        icon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _sdtController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        icon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập SĐT' : null,
                    ),
                    const SizedBox(height: 16),

                    // 5. THÊM Ô NHẬP EMAIL (TÙY CHỌN)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Không bắt buộc)', // Ghi rõ cho người dùng
                        hintText: 'Nhập email để nhận vé đặt bàn',
                        helperText: 'Vé xác nhận sẽ được gửi qua email này', // Dòng chú thích nhỏ bên dưới
                        icon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      // Validator check: Nếu có nhập thì phải đúng định dạng, không nhập thì thôi
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@')) return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Validate số người dựa trên TỔNG SỨC CHỨA
                    TextFormField(
                      controller: _soNguoiController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng người',
                        icon: Icon(Icons.people),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng nhập số người';
                        final soNguoi = int.tryParse(value);
                        if (soNguoi == null || soNguoi <= 0) return 'Số người không hợp lệ';

                        // So sánh với Tổng sức chứa
                        if (soNguoi > _tongSucChua) {
                          return 'Vượt quá sức chứa (Tối đa: $_tongSucChua)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text('Thời gian khách đến:', style: Theme.of(context).textTheme.titleMedium),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('dd/MM/yyyy, HH:mm').format(provider.selectedDateTime),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.deepPurple, size: 30),
                          onPressed: () => provider.pickDateTime(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    TextFormField(
                      controller: _ghiChuController,
                      decoration: const InputDecoration(
                        labelText: 'Yêu cầu đặc biệt (nếu có)',
                        icon: Icon(Icons.note_alt),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : () => _handleSubmit(provider),
                      icon: provider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(provider.isLoading ? 'Đang xử lý...' : 'Xác Nhận Đặt Bàn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}