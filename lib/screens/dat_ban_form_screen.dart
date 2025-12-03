import 'package:flutter/material.dart';
import 'package:front_end_app/providers/dat_ban_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // << Import providers
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ban_an.dart';
import '../models/dat_ban_dto.dart';
import '../services/khach_hang_service.dart';

class DatBanFormScreen extends StatefulWidget {
  final List<BanAn> danhSachBan;
  final int soNguoi;
  final DateTime thoiGian;

  const DatBanFormScreen({
    Key? key, 
    required this.danhSachBan,
    required this.soNguoi,
    required this.thoiGian,
  }) : super(key: key);

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
  
  // Tra cứu khách hàng
  final _khachHangService = KhachHangService();
  bool _isLookingUpCustomer = false;
  String? _lookupMessage;
  String? _lookupStatus; // 'success', 'notfound', 'error'
  String? _foundCustomerId;
  bool _wantEmailNotification = false;
  bool _wantDeposit = false;
  double _depositAmount = 0;

  @override
  void initState() {
    super.initState();
    // Set số lượng người từ màn hình chọn bàn
    _soNguoiController.text = widget.soNguoi.toString();
    _tinhToanThongTinBan();
    _autoFillUserData(); // Tự điền thông tin nếu có
    _debugCheckStorage(); // Kiểm tra bộ nhớ máy (debug)
    
    // Tự động tính tiền cọc nếu số người >= 6
    if (widget.soNguoi >= 6) {
      _calculateDeposit(widget.soNguoi);
      _wantDeposit = true;
    }
  }
  
  // Tính tiền cọc theo logic web: >= 6 người thì 50k/người, tối thiểu 200k
  void _calculateDeposit(int soNguoi) {
    if (soNguoi >= 6) {
      final donGiaCoc = 50000;
      double tienCoc = (soNguoi * donGiaCoc).toDouble();
      if (tienCoc < 200000) {
        tienCoc = 200000;
      }
      setState(() {
        _depositAmount = tienCoc;
        _wantDeposit = true;
      });
    } else {
      setState(() {
        _depositAmount = 0;
      });
    }
  }
  
  // Tra cứu khách hàng theo số điện thoại
  Future<void> _lookupCustomer() async {
    final phone = _sdtController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại để tra cứu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLookingUpCustomer = true;
      _lookupMessage = null;
      _lookupStatus = null;
    });
    
    try {
      final result = await _khachHangService.searchByPhone(phone);
      setState(() {
        _isLookingUpCustomer = false;
        if (result.found) {
          _foundCustomerId = result.maKhachHang;
          _tenKhachController.text = result.tenKhach ?? _tenKhachController.text;
          _sdtController.text = phone;
          if (result.email != null && result.email!.isNotEmpty) {
            _emailController.text = result.email!;
          }
          _lookupStatus = 'success';
          _lookupMessage = result.message ?? 'Đã tìm thấy khách hàng thân thiết.';
        } else {
          _foundCustomerId = null;
          _lookupStatus = 'notfound';
          _lookupMessage = result.message ?? 'Không tìm thấy khách hàng. Bạn có thể tiếp tục nhập thông tin như khách mới.';
        }
      });
    } catch (e) {
      setState(() {
        _isLookingUpCustomer = false;
        _lookupStatus = 'error';
        _lookupMessage = 'Lỗi tra cứu: $e';
      });
    }
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
      
      // Validation: Kiểm tra đủ sức chứa
      final soNguoi = widget.soNguoi;
      if (soNguoi > _tongSucChua) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số người ($soNguoi) vượt quá sức chứa ($_tongSucChua). Vui lòng quay lại màn hình chọn bàn để chọn thêm bàn.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // 3. LẤY THÔNG TIN TỪ SHAREDPREFERENCES NGAY LÚC SUBMIT
      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('maKhachHang'); // Lấy ID đã lưu

      // Nếu chuỗi rỗng thì coi như null (khách vãng lai)
      if (currentUserId != null && currentUserId.isEmpty) {
        currentUserId = null;
      }

      // Xử lý Email: Chỉ gửi nếu người dùng muốn nhận email notification
      String? emailToSend = null;
      if (_wantEmailNotification && _emailController.text.trim().isNotEmpty) {
        emailToSend = _emailController.text.trim();
      }
      
      // Xử lý tiền cọc
      double tienCocToSend = 0;
      if (_wantDeposit && _depositAmount > 0) {
        tienCocToSend = _depositAmount;
      }

      String? maNhanVienHienTai = "NV000";

      // Tạo danh sách ID bàn (giống web: tableIds)
      final List<String> tableIds = widget.danhSachBan
          .map((ban) => ban.maBan ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // Xử lý ghi chú: nếu có nhiều bàn thì thêm thông tin gộp bàn
      String? finalGhiChu;
      if (widget.danhSachBan.length > 1) {
        finalGhiChu = "Gộp bàn: $_tenCacBan. ${_ghiChuController.text}".trim();
        if (finalGhiChu.endsWith('.')) {
          finalGhiChu = finalGhiChu.substring(0, finalGhiChu.length - 1);
        }
      } else {
        finalGhiChu = _ghiChuController.text.isEmpty ? null : _ghiChuController.text;
      }

      final dto = DatBanDto(
        // Gửi danh sách bàn (giống web)
        tableIds: tableIds.isNotEmpty ? tableIds : null,
        // Fallback: nếu không có bàn nào thì để null (nhà hàng sẽ sắp xếp)
        maBan: tableIds.isEmpty ? null : (tableIds.length == 1 ? tableIds.first : null),
        
        hoTenKhach: _tenKhachController.text.trim(),
        soDienThoaiKhach: _sdtController.text.trim(),
        thoiGianDatHang: provider.selectedDateTime,
        soLuongNguoi: widget.soNguoi,
        ghiChu: finalGhiChu,
        maNhanVien: maNhanVienHienTai,

        // Điền dữ liệu chuẩn vào DTO (giống web)
        maKhachHang: _foundCustomerId ?? currentUserId, // Ưu tiên ID từ tra cứu
        email: emailToSend,         // Email chỉ gửi nếu muốn nhận notification
        tienDatCoc: tienCocToSend > 0 ? tienCocToSend : null,  // Chỉ gửi nếu > 0
        source: 'App', // Nguồn đặt bàn từ Flutter app
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
      create: (_) {
        final provider = DatBanProvider();
        // Set thời gian từ màn hình chọn bàn
        provider.setDateTime(widget.thoiGian);
        return provider;
      },
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
                    // Nút tra cứu khách hàng
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sdtController,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              icon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập SĐT' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isLookingUpCustomer ? null : _lookupCustomer,
                          icon: _isLookingUpCustomer
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Tra cứu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    
                    // Hiển thị kết quả tra cứu
                    if (_lookupMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lookupStatus == 'success'
                              ? Colors.green.shade50
                              : _lookupStatus == 'notfound'
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50,
                          border: Border.all(
                            color: _lookupStatus == 'success'
                                ? Colors.green
                                : _lookupStatus == 'notfound'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _lookupMessage!,
                          style: TextStyle(
                            color: _lookupStatus == 'success'
                                ? Colors.green.shade900
                                : _lookupStatus == 'notfound'
                                    ? Colors.orange.shade900
                                    : Colors.red.shade900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Checkbox email notification
                    CheckboxListTile(
                      title: const Text('Tôi muốn nhận email xác nhận'),
                      value: _wantEmailNotification,
                      onChanged: (value) {
                        setState(() {
                          _wantEmailNotification = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Ô nhập email (chỉ hiện khi muốn nhận email)
                    if (_wantEmailNotification)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Nhập email để nhận vé đặt bàn',
                            icon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (_wantEmailNotification) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Số lượng người (chỉ đọc - lấy từ màn hình chọn bàn)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepPurple.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.shade100,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _soNguoiController,
                        decoration: InputDecoration(
                          labelText: 'Số lượng người',
                          labelStyle: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: Icon(
                            Icons.people,
                            color: Colors.deepPurple.shade600,
                            size: 28,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        readOnly: true,
                        enabled: false,
                        style: TextStyle(
                          color: Colors.deepPurple.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    
                    // Hiển thị cảnh báo tiền cọc nếu >= 6 người
                    if (widget.soNguoi >= 6)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Yêu cầu đặt cọc',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Với ${widget.soNguoi} khách, nhà hàng yêu cầu đặt cọc để giữ chỗ.',
                            ),
                            Text(
                              'Số tiền đặt cọc: ${NumberFormat("#,###").format(_depositAmount)} VNĐ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Checkbox đặt cọc (tự động bật nếu >= 6 người)
                    CheckboxListTile(
                      title: Text(widget.soNguoi >= 6
                          ? 'Đặt cọc bắt buộc (tự động)'
                          : 'Tôi muốn đặt cọc để giữ chỗ'),
                      value: _wantDeposit,
                      onChanged: widget.soNguoi >= 6
                          ? null
                          : (value) {
                              setState(() {
                                _wantDeposit = value ?? false;
                                if (!_wantDeposit) {
                                  _depositAmount = 0;
                                } else if (_depositAmount == 0) {
                                  _depositAmount = 200000;
                                }
                              });
                            },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Hiển thị số tiền cọc nếu có
                    if (_wantDeposit && _depositAmount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số tiền đặt cọc: ${NumberFormat("#,###").format(_depositAmount)} VNĐ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Số tiền này sẽ được tính tự động và yêu cầu thanh toán online để hoàn tất đặt bàn.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    Text('Thời gian khách đến:', style: Theme.of(context).textTheme.titleMedium),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.deepPurple, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy, HH:mm').format(provider.selectedDateTime),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    
                    // Hiển thị thông tin bàn đã chọn
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.danhSachBan.isEmpty
                                ? 'Chưa chọn bàn (nhà hàng sẽ sắp xếp giúp bạn)'
                                : 'Đã chọn ${widget.danhSachBan.length} bàn · tổng sức chứa $_tongSucChua khách',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.danhSachBan.isEmpty 
                                  ? Colors.grey.shade600 
                                  : Colors.black87,
                            ),
                          ),
                          
                          // Hiển thị cảnh báo nếu thiếu chỗ
                          if (widget.danhSachBan.isNotEmpty)
                            Builder(
                              builder: (context) {
                                final soNguoi = widget.soNguoi;
                                final remainingGuests = soNguoi > 0 
                                    ? (soNguoi - _tongSucChua).clamp(0, double.infinity).toInt()
                                    : 0;
                                final hasEnoughCapacity = _tongSucChua >= soNguoi;
                                
                                if (remainingGuests > 0) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      border: Border.all(color: Colors.orange),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Còn thiếu $remainingGuests chỗ để đủ cho $soNguoi khách. Vui lòng quay lại màn hình chọn bàn để chọn thêm bàn.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  );
                                } else if (hasEnoughCapacity && soNguoi > 0) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Đủ chỗ cho khách. Nếu cần ghép sát nhau, hãy ghi chú để nhà hàng hỗ trợ.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ),
                    
                    // Hiển thị danh sách bàn đã chọn với nút xóa
                    if (widget.danhSachBan.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...widget.danhSachBan.map((ban) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ban.tenBan,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (ban.tenTang != null)
                                      Text(
                                        '(${ban.tenTang})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    Text(
                                      '- ${ban.sucChua ?? 0} khách',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  // Không cho phép xóa trong form này vì đã chọn từ màn hình trước
                                  // Chỉ hiển thị để người dùng biết đã chọn những bàn nào
                                },
                                tooltip: 'Bàn đã được chọn từ màn hình trước',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    
                    const SizedBox(height: 20),

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
                    
                    // Validation: Disable nút nếu không đủ sức chứa
                    Builder(
                      builder: (context) {
                        final soNguoi = widget.soNguoi;
                        final hasEnoughCapacity = widget.danhSachBan.isEmpty || _tongSucChua >= soNguoi;
                        final canSubmit = _tenKhachController.text.isNotEmpty &&
                            _sdtController.text.isNotEmpty &&
                            soNguoi > 0 &&
                            hasEnoughCapacity;
                        
                        return ElevatedButton.icon(
                          onPressed: (provider.isLoading || !canSubmit) 
                              ? null 
                              : () => _handleSubmit(provider),
                      icon: provider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                          : const Icon(Icons.check_circle_outline),
                          label: Text(provider.isLoading 
                              ? 'Đang xử lý...' 
                              : canSubmit 
                                  ? 'Gửi yêu cầu đặt bàn'
                                  : 'Vui lòng điền đầy đủ thông tin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSubmit ? Colors.green : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
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