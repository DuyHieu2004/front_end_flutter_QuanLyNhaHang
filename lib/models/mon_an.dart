import 'hinh_anh.dart';
import 'phien_ban_mon_an.dart';

class MonAn {
  final String maMonAn;
  final String tenMonAn;
  final double gia; // Giá mặc định (giá nhỏ nhất từ các phiên bản)
  final String maDanhMuc;
  final String? tenDanhMuc;
  final bool isShow;
  final List<HinhAnhMonAn> hinhAnhMonAns;
  final List<PhienBanMonAn> phienBanMonAns; // Danh sách các phiên bản (size) với giá

  MonAn({
    required this.maMonAn,
    required this.tenMonAn,
    required this.gia,
    required this.maDanhMuc,
    this.tenDanhMuc,
    this.isShow = true,
    required this.hinhAnhMonAns,
    required this.phienBanMonAns,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    // Parse hình ảnh
    final hinhAnhList = (json['hinhAnhMonAns'] ?? json['HinhAnhMonAns'] as List?) ?? [];
    final images = hinhAnhList.map((i) {
      // Backend trả về HinhAnhDTO với URLHinhAnh
      if (i is Map<String, dynamic>) {
        return HinhAnhMonAn.fromJson({
          'urlHinhAnh': i['urlHinhAnh'] ?? i['URLHinhAnh'] ?? '',
        });
      }
      return HinhAnhMonAn.fromJson(i);
    }).toList();

    // Parse phiên bản món ăn
    final phienBanList = (json['phienBanMonAns'] ?? json['PhienBanMonAns'] as List?) ?? [];
    final phienBans = phienBanList.map((pb) => PhienBanMonAn.fromJson(pb)).toList();

    // Tính giá mặc định (giá nhỏ nhất từ các phiên bản)
    double defaultGia = 0.0;
    if (phienBans.isNotEmpty) {
      defaultGia = phienBans.map((pb) => pb.gia).reduce((a, b) => a < b ? a : b);
    } else if (json['gia'] != null) {
      defaultGia = (json['gia'] is num) ? (json['gia'] as num).toDouble() : 0.0;
    }

    return MonAn(
      maMonAn: json['maMonAn'] ?? json['MaMonAn'] ?? '',
      tenMonAn: json['tenMonAn'] ?? json['TenMonAn'] ?? '',
      gia: defaultGia,
      maDanhMuc: json['maDanhMuc'] ?? json['MaDanhMuc'] ?? '',
      tenDanhMuc: json['tenDanhMuc'] ?? json['TenDanhMuc'],
      isShow: json['isShow'] ?? json['IsShow'] ?? true,
      hinhAnhMonAns: images,
      phienBanMonAns: phienBans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maMonAn': maMonAn,
      'tenMonAn': tenMonAn,
      'gia': gia,
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'isShow': isShow,
      'hinhAnhMonAns': hinhAnhMonAns.map((h) => h.toJson()).toList(),
      'phienBanMonAns': phienBanMonAns.map((pb) => pb.toJson()).toList(),
    };
  }
}