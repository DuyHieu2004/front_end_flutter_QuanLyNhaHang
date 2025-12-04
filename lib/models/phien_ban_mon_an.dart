class PhienBanMonAn {
  final String maPhienBan;
  final String tenPhienBan;
  final double gia;
  final String? maTrangThai;
  final String? tenTrangThai;
  final bool isShow;
  final int? thuTu;

  PhienBanMonAn({
    required this.maPhienBan,
    required this.tenPhienBan,
    required this.gia,
    this.maTrangThai,
    this.tenTrangThai,
    this.isShow = true,
    this.thuTu,
  });

  factory PhienBanMonAn.fromJson(Map<String, dynamic> json) {
    return PhienBanMonAn(
      maPhienBan: json['maPhienBan'] ?? json['MaPhienBan'] ?? '',
      tenPhienBan: json['tenPhienBan'] ?? json['TenPhienBan'] ?? '',
      gia: json['gia'] != null
          ? (json['gia'] is int ? json['gia'].toDouble() : json['gia'])
          : (json['Gia'] != null
              ? (json['Gia'] is int ? json['Gia'].toDouble() : json['Gia'])
              : 0.0),
      maTrangThai: json['maTrangThai'] ?? json['MaTrangThai'],
      tenTrangThai: json['tenTrangThai'] ?? json['TenTrangThai'],
      isShow: json['isShow'] ?? json['IsShow'] ?? true,
      thuTu: json['thuTu'] ?? json['ThuTu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maPhienBan': maPhienBan,
      'tenPhienBan': tenPhienBan,
      'gia': gia,
      'maTrangThai': maTrangThai,
      'tenTrangThai': tenTrangThai,
      'isShow': isShow,
      'thuTu': thuTu,
    };
  }
}

