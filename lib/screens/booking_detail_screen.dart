import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/don_hang_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String maDonHang;

  const BookingDetailScreen({Key? key, required this.maDonHang}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final DonHangService _donHangService = DonHangService();
  late Future<dynamic> _detailFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy chi tiết khi màn hình mở lên
    _detailFuture = _donHangService.getMyBookingDetail(maDonHang: widget.maDonHang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi Tiết Đơn Hàng"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<dynamic>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Không tìm thấy dữ liệu."));
          }

          final detail = snapshot.data!;
          // Xử lý cả PascalCase và camelCase từ backend
          final monAns = detail['monAns'] ?? detail['MonAns'] ?? [];
          final monAnsList = monAns is List ? monAns : <dynamic>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PHẦN 1: THÔNG TIN CHUNG ---
                _buildSectionTitle("Thông tin đặt bàn"),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.receipt, "Mã đơn:", detail['maDonHang'] ?? detail['MaDonHang'] ?? '---'),
                        _buildInfoRow(Icons.person, "Người đặt:", detail['tenNguoiDat'] ?? detail['TenNguoiDat'] ?? detail['tenNguoiNhan'] ?? detail['TenNguoiNhan'] ?? "Chính chủ"),
                        _buildInfoRow(Icons.phone, "SĐT liên hệ:", detail['sdtNguoiDat'] ?? detail['SDTNguoiDat'] ?? detail['sdtNguoiNhan'] ?? detail['SDTNguoiNhan'] ?? "--"),
                        _buildInfoRow(Icons.access_time, "Thời gian:", _formatDateTime(detail['thoiGianDat'] ?? detail['ThoiGianDat'] ?? detail['thoiGianDatHang'] ?? detail['ThoiGianDatHang'])),
                        _buildInfoRow(Icons.people, "Số khách:", "${detail['soNguoi'] ?? detail['SoNguoi'] ?? 0} người"),
                        _buildInfoRow(Icons.info_outline, "Trạng thái:", detail['trangThai'] ?? detail['TrangThai'] ?? detail['tenTrangThai'] ?? detail['TenTrangThai'] ?? '---', color: Colors.blue),
                        if ((detail['ghiChu'] ?? detail['GhiChu'] ?? '').toString().isNotEmpty)
                          _buildInfoRow(Icons.note, "Ghi chú:", detail['ghiChu'] ?? detail['GhiChu'] ?? ''),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- PHẦN 2: THÔNG TIN CỌC (NẾU CÓ) ---
                Builder(
                  builder: (context) {
                    final tienDatCoc = (detail['tienDatCoc'] ?? detail['TienDatCoc'] ?? 0).toDouble();
                    if (tienDatCoc > 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Thanh toán"),
                          Card(
                            color: Colors.green[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _buildInfoRow(
                                  Icons.monetization_on,
                                  "Đã đặt cọc:",
                                  "${NumberFormat("#,###").format(tienDatCoc)} đ",
                                  color: Colors.red[700],
                                  isBold: true
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // --- PHẦN 3: DANH SÁCH MÓN ĂN ---
                _buildSectionTitle("Thực đơn đã chọn (${monAnsList.length} món)"),
                if (monAnsList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Chưa chọn món nào.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  )
                else
                  Builder(
                    builder: (context) {
                      // Tính tổng tiền và tiền đặt cọc
                      final totalAmount = monAnsList.fold<double>(0.0, (sum, m) {
                        final donGia = (m['donGia'] ?? m['DonGia'] ?? 0).toDouble();
                        final soLuong = (m['soLuong'] ?? m['SoLuong'] ?? 0).toInt();
                        return sum + (donGia * soLuong);
                      });
                      final tienDatCoc = (detail['tienDatCoc'] ?? detail['TienDatCoc'] ?? 0).toDouble();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monAnsList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var m = monAnsList[index];
                      // Xử lý cả PascalCase và camelCase
                      final tenMon = m['tenMon'] ?? m['TenMon'] ?? 'Món không xác định';
                      final tenPhienBan = m['tenPhienBan'] ?? m['TenPhienBan'] ?? '';
                      final donGia = (m['donGia'] ?? m['DonGia'] ?? 0).toDouble();
                      final soLuong = (m['soLuong'] ?? m['SoLuong'] ?? 0).toInt();
                      final hinhAnh = m['hinhAnh'] ?? m['HinhAnh'] ?? '';
                      final thanhTien = donGia * soLuong;
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: hinhAnh.toString().isNotEmpty
                              ? Image.network(
                                  hinhAnh.toString(),
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                )
                              : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                        ),
                        title: Text(tenMon.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${tenPhienBan.toString()} - ${NumberFormat("#,###").format(donGia)} đ"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("x$soLuong", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              "${NumberFormat("#,###").format(thanhTien)} đ",
                              style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                          // Hiển thị tổng tiền
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.deepPurple.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Tổng tiền:",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${NumberFormat("#,###").format(totalAmount)} đ",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Hiển thị số tiền cần thanh toán (nếu có đặt cọc)
                          if (tienDatCoc > 0) ...[
                            const SizedBox(height: 8),
                            Card(
                              color: Colors.orange.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Cần thanh toán:",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${NumberFormat("#,###").format(totalAmount - tienDatCoc)} đ",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(
                value,
                style: TextStyle(
                    color: color ?? Colors.black87,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15
                )
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return '---';
    try {
      final dateTimeStr = dateTimeValue.toString();
      if (dateTimeStr.isEmpty) return '---';
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateTimeValue.toString();
    }
  }
}