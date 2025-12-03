class DatBanDto {
  // Thay đổi: Hỗ trợ nhiều bàn thay vì chỉ một bàn (giống web)
  final List<String>? tableIds; // Danh sách ID bàn (ưu tiên)
  final String? maBan; // Giữ lại để tương thích ngược (nếu chỉ có 1 bàn)
  
  final String hoTenKhach;
  final String soDienThoaiKhach;
  final DateTime thoiGianDatHang;
  final int soLuongNguoi;
  final String? ghiChu;
  final String? maNhanVien;

  // === CÁC TRƯỜNG BỔ SUNG ===
  final String? maKhachHang; // ID khách (nếu đã đăng nhập) - tương đương customerId trong web
  final String? email;       // Email (để nhận vé)
  final double? tienDatCoc;  // Tiền đặt cọc (C# decimal -> Dart double)
  final String? source;      // Nguồn đặt bàn: "App" (giống web)

  DatBanDto({
    this.tableIds, // Danh sách bàn (ưu tiên)
    this.maBan,    // Một bàn (tương thích ngược)
    required this.hoTenKhach,
    required this.soDienThoaiKhach,
    required this.thoiGianDatHang,
    required this.soLuongNguoi,
    this.ghiChu,
    this.maNhanVien,
    this.maKhachHang,
    this.email,
    this.tienDatCoc,
    this.source, // Mặc định "App" cho Flutter
  });

  Map<String, dynamic> toJson() {
    // Format đúng với backend: PascalCase (giống web thực tế gửi)
    final json = <String, dynamic>{
      'HoTenKhach': hoTenKhach,
      'SoDienThoaiKhach': soDienThoaiKhach,
      'ThoiGianDatHang': thoiGianDatHang.toIso8601String(), // ISO string như web
      'SoLuongNguoi': soLuongNguoi,
    };

    // Danh sách bàn (bắt buộc)
    final tableIdsValue = tableIds;
    if (tableIdsValue != null && tableIdsValue.isNotEmpty) {
      json['DanhSachMaBan'] = tableIdsValue; // Backend yêu cầu DanhSachMaBan
    } else {
      // Fallback: nếu không có tableIds thì dùng maBan
      final maBanValue = maBan;
      if (maBanValue != null && maBanValue.isNotEmpty) {
        json['DanhSachMaBan'] = [maBanValue]; // Chuyển thành array
      }
    }

    // Ghi chú (optional)
    final ghiChuValue = ghiChu;
    if (ghiChuValue != null && ghiChuValue.isNotEmpty) {
      json['GhiChu'] = ghiChuValue;
    }

    // Mã nhân viên (optional)
    final maNhanVienValue = maNhanVien;
    if (maNhanVienValue != null && maNhanVienValue.isNotEmpty) {
      json['MaNhanVien'] = maNhanVienValue;
    }

    // Mã khách hàng (optional)
    final maKhachHangValue = maKhachHang;
    if (maKhachHangValue != null && maKhachHangValue.isNotEmpty) {
      json['MaKhachHang'] = maKhachHangValue;
    }
    
    // Email (optional)
    final emailValue = email;
    if (emailValue != null && emailValue.isNotEmpty) {
      json['Email'] = emailValue;
    }
    
    // Tiền đặt cọc (optional - chỉ gửi nếu > 0, giống web)
    final tienDatCocValue = tienDatCoc;
    if (tienDatCocValue != null && tienDatCocValue > 0) {
      json['TienDatCoc'] = tienDatCocValue;
    }

    return json;
  }
}