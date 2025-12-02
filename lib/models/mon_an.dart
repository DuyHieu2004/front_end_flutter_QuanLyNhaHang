import 'hinh_anh.dart';

class MonAn {
  final String maMonAn;
  final String tenMonAn;
  final double gia;
  final String maDanhMuc;
  final List<HinhAnhMonAn> hinhAnhMonAns;

  MonAn({
    required this.maMonAn,
    required this.tenMonAn,
    required this.gia,
    required this.maDanhMuc,
    required this.hinhAnhMonAns,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    // Đảm bảo danh sách hình ảnh không bị null
    final hinhAnhList = (json['hinhAnhMonAns'] as List?) ?? [];
    final images =
        hinhAnhList.map((i) => HinhAnhMonAn.fromJson(i)).toList();

    return MonAn(
      maMonAn: json['maMonAn'],
      tenMonAn: json['tenMonAn'],
      // Tránh lỗi "type 'Null' is not a subtype of type 'num' in type cast"
      // Nếu backend trả null hoặc kiểu không phải number, gán mặc định = 0
      gia: (json['gia'] is num) ? (json['gia'] as num).toDouble() : 0.0,
      maDanhMuc: json['maDanhMuc'],
      hinhAnhMonAns: images,
    );
  }
}