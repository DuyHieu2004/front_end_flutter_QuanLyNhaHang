class BanAn {
  final String maBan;
  final String tenBan;
  final String? tenTrangThai;
  final int sucChua;
  String? tenTang;

  BanAn({
    required this.maBan,
    required this.tenBan,
    this.tenTrangThai,
    required this.sucChua,
    this.tenTang,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      maBan: json['maBan'] as String,
      tenBan: json['tenBan'] as String,
      tenTrangThai: json['tenTrangThai'] as String?,
      // Nếu backend trả null hoặc không phải số, gán mặc định = 0
      sucChua: (json['sucChua'] is num)
          ? (json['sucChua'] as num).toInt()
          : 0,
      tenTang: json['tenTang'],
    );
  }
}