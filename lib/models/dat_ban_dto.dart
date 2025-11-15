class DatBanDto {
  final String maBan;
  final String hoTenKhach;
  final String soDienThoaiKhach;
  final DateTime thoiGianDatHang;
  final int soLuongNguoi;
  final String? ghiChu;
  final String? maNhanVien;

  // === CÁC TRƯỜNG BỔ SUNG ===
  final String? maKhachHang; // ID khách (nếu đã đăng nhập)
  final String? email;       // Email (để nhận vé)
  final double? tienDatCoc;  // <--- ĐÂY RỒI: Tiền đặt cọc (C# decimal -> Dart double)

  DatBanDto({
    required this.maBan,
    required this.hoTenKhach,
    required this.soDienThoaiKhach,
    required this.thoiGianDatHang,
    required this.soLuongNguoi,
    this.ghiChu,
    this.maNhanVien,
    this.maKhachHang,
    this.email,
    this.tienDatCoc, // <--- Thêm vào constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'maBan': maBan,
      'hoTenKhach': hoTenKhach,
      'soDienThoaiKhach': soDienThoaiKhach,
      'thoiGianDatHang': thoiGianDatHang.toIso8601String(),
      'soLuongNguoi': soLuongNguoi,
      'ghiChu': ghiChu,
      'maNhanVien': maNhanVien,
      'maKhachHang': maKhachHang,
      'email': email,
      'tienDatCoc': tienDatCoc, // <--- Map vào JSON gửi lên Server
    };
  }
}