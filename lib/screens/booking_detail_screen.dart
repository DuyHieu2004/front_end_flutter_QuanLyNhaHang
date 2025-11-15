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
          final monAns = detail['monAns'] as List;

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
                        _buildInfoRow(Icons.receipt, "Mã đơn:", detail['maDonHang']),
                        _buildInfoRow(Icons.person, "Người đặt:", detail['tenNguoiDat'] ?? "Chính chủ"),
                        _buildInfoRow(Icons.phone, "SĐT liên hệ:", detail['sdtNguoiDat'] ?? "--"),
                        _buildInfoRow(Icons.access_time, "Thời gian:", DateFormat('HH:mm dd/MM/yyyy').format(DateTime.parse(detail['thoiGianDat']))),
                        _buildInfoRow(Icons.people, "Số khách:", "${detail['soNguoi']} người"),
                        _buildInfoRow(Icons.info_outline, "Trạng thái:", detail['trangThai'], color: Colors.blue),
                        if (detail['ghiChu'] != null && detail['ghiChu'].isNotEmpty)
                          _buildInfoRow(Icons.note, "Ghi chú:", detail['ghiChu']),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- PHẦN 2: THÔNG TIN CỌC (NẾU CÓ) ---
                if (detail['tienDatCoc'] != null && detail['tienDatCoc'] > 0) ...[
                  _buildSectionTitle("Thanh toán"),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildInfoRow(
                          Icons.monetization_on,
                          "Đã đặt cọc:",
                          "${NumberFormat("#,###").format(detail['tienDatCoc'])} đ",
                          color: Colors.red[700],
                          isBold: true
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- PHẦN 3: DANH SÁCH MÓN ĂN ---
                _buildSectionTitle("Thực đơn đã chọn (${monAns.length} món)"),
                if (monAns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Chưa chọn món nào.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monAns.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var m = monAns[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            m['hinhAnh'] ?? "",
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                          ),
                        ),
                        title: Text(m['tenMon'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${m['tenPhienBan']} - ${NumberFormat("#,###").format(m['donGia'])} đ"),
                        trailing: Text("x${m['soLuong']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}