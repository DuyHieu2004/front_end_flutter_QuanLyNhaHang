class BanAn {
  final String maBan;
  final String tenBan;
  final String? tenTrangThai;
  final String? maTrangThai; // Mã trạng thái gốc
  final String? trangThaiHienThi; // Trạng thái hiển thị (từ GetManagerTableStatus)
  final int sucChua;
  String? tenTang;
  String? ghiChu; // Ghi chú (có thể chứa mã đơn hàng)
  String? maDonHang; // Mã đơn hàng (extract từ ghiChu hoặc từ API)

  BanAn({
    required this.maBan,
    required this.tenBan,
    this.tenTrangThai,
    this.maTrangThai,
    this.trangThaiHienThi,
    required this.sucChua,
    this.tenTang,
    this.ghiChu,
    this.maDonHang,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase và camelCase từ backend
    final maBanValue = json['maBan'] ?? json['MaBan'];
    final tenBanValue = json['tenBan'] ?? json['TenBan'];
    final tenTrangThaiValue = json['tenTrangThai'] ?? json['TenTrangThai'] ?? json['TrangThaiHienThi'];
    final trangThaiHienThiValue = json['trangThaiHienThi'] ?? json['TrangThaiHienThi'];
    final maTrangThaiValue = json['maTrangThai'] ?? json['MaTrangThai'] ?? json['MaTrangThaiGoc'];
    final sucChuaValue = json['sucChua'] ?? json['SucChua'];
    final tenTangValue = json['tenTang'] ?? json['TenTang'];
    final ghiChuValue = json['ghiChu'] ?? json['GhiChu'];
    final maDonHangValue = json['maDonHang'] ?? json['MaDonHang'];
    
    // Validate required fields
    if (maBanValue == null) {
      throw Exception('maBan is required but was null. JSON: $json');
    }
    if (tenBanValue == null) {
      throw Exception('tenBan is required but was null. JSON: $json');
    }
    
    // Extract mã đơn hàng từ ghiChu nếu có (format: "Đơn #DH001")
    String? extractedMaDonHang = maDonHangValue?.toString();
    if (extractedMaDonHang == null && ghiChuValue != null) {
      final regex = RegExp(r'Đơn\s*#([A-Z0-9]+)');
      final match = regex.firstMatch(ghiChuValue.toString());
      if (match != null) {
        extractedMaDonHang = match.group(1);
      }
    }

    return BanAn(
      maBan: maBanValue.toString(),
      tenBan: tenBanValue.toString(),
      tenTrangThai: tenTrangThaiValue?.toString(),
      maTrangThai: maTrangThaiValue?.toString(),
      trangThaiHienThi: trangThaiHienThiValue?.toString(),
      // Nếu backend trả null hoặc không phải số, gán mặc định = 0
      sucChua: (sucChuaValue is num)
          ? sucChuaValue.toInt()
          : (sucChuaValue != null ? int.tryParse(sucChuaValue.toString()) ?? 0 : 0),
      tenTang: tenTangValue?.toString(),
      ghiChu: ghiChuValue?.toString(),
      maDonHang: extractedMaDonHang,
    );
  }
}