class Menu {
  final String maMenu;
  final String tenMenu;
  final String? loaiMenu;
  final double? giaMenu;
  final double? giaGoc;
  final double? phanTramGiamGia;
  final String? moTa;
  final String? hinhAnh;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final List<ChiTietMenu>? chiTietMenus;

  Menu({
    required this.maMenu,
    required this.tenMenu,
    this.loaiMenu,
    this.giaMenu,
    this.giaGoc,
    this.phanTramGiamGia,
    this.moTa,
    this.hinhAnh,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.chiTietMenus,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      maMenu: json['maMenu'] ?? json['MaMenu'] ?? '',
      tenMenu: json['tenMenu'] ?? json['TenMenu'] ?? '',
      loaiMenu: json['loaiMenu'] ?? json['LoaiMenu'],
      giaMenu: json['giaMenu'] != null 
          ? (json['giaMenu'] is int ? json['giaMenu'].toDouble() : json['giaMenu'])
          : (json['GiaMenu'] != null 
              ? (json['GiaMenu'] is int ? json['GiaMenu'].toDouble() : json['GiaMenu'])
              : null),
      giaGoc: json['giaGoc'] != null
          ? (json['giaGoc'] is int ? json['giaGoc'].toDouble() : json['giaGoc'])
          : (json['GiaGoc'] != null
              ? (json['GiaGoc'] is int ? json['GiaGoc'].toDouble() : json['GiaGoc'])
              : null),
      phanTramGiamGia: json['phanTramGiamGia'] != null
          ? (json['phanTramGiamGia'] is int ? json['phanTramGiamGia'].toDouble() : json['phanTramGiamGia'])
          : (json['PhanTramGiamGia'] != null
              ? (json['PhanTramGiamGia'] is int ? json['PhanTramGiamGia'].toDouble() : json['PhanTramGiamGia'])
              : null),
      moTa: json['moTa'] ?? json['MoTa'],
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],
      ngayBatDau: json['ngayBatDau'] != null 
          ? DateTime.parse(json['ngayBatDau'])
          : (json['NgayBatDau'] != null ? DateTime.parse(json['NgayBatDau']) : null),
      ngayKetThuc: json['ngayKetThuc'] != null
          ? DateTime.parse(json['ngayKetThuc'])
          : (json['NgayKetThuc'] != null ? DateTime.parse(json['NgayKetThuc']) : null),
      chiTietMenus: json['chiTietMenus'] != null
          ? (json['chiTietMenus'] as List).map((e) => ChiTietMenu.fromJson(e)).toList()
          : (json['ChiTietMenus'] != null
              ? (json['ChiTietMenus'] as List).map((e) => ChiTietMenu.fromJson(e)).toList()
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maMenu': maMenu,
      'tenMenu': tenMenu,
      'loaiMenu': loaiMenu,
      'giaMenu': giaMenu,
      'giaGoc': giaGoc,
      'phanTramGiamGia': phanTramGiamGia,
      'moTa': moTa,
      'hinhAnh': hinhAnh,
      'ngayBatDau': ngayBatDau?.toIso8601String(),
      'ngayKetThuc': ngayKetThuc?.toIso8601String(),
      'chiTietMenus': chiTietMenus?.map((e) => e.toJson()).toList(),
    };
  }
}

class ChiTietMenu {
  final int? soLuong;
  final String? ghiChu;
  final MonAnTrongMenu? monAn;

  ChiTietMenu({
    this.soLuong,
    this.ghiChu,
    this.monAn,
  });

  factory ChiTietMenu.fromJson(Map<String, dynamic> json) {
    return ChiTietMenu(
      soLuong: json['soLuong'] ?? json['SoLuong'],
      ghiChu: json['ghiChu'] ?? json['GhiChu'],
      monAn: json['monAn'] != null
          ? MonAnTrongMenu.fromJson(json['monAn'])
          : (json['MonAn'] != null ? MonAnTrongMenu.fromJson(json['MonAn']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soLuong': soLuong,
      'ghiChu': ghiChu,
      'monAn': monAn?.toJson(),
    };
  }
}

class MonAnTrongMenu {
  final String? tenMonAn;
  final String? hinhAnh;
  final double? gia;

  MonAnTrongMenu({
    this.tenMonAn,
    this.hinhAnh,
    this.gia,
  });

  factory MonAnTrongMenu.fromJson(Map<String, dynamic> json) {
    return MonAnTrongMenu(
      tenMonAn: json['tenMonAn'] ?? json['TenMonAn'],
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],
      gia: json['gia'] != null
          ? (json['gia'] is int ? json['gia'].toDouble() : json['gia'])
          : (json['Gia'] != null
              ? (json['Gia'] is int ? json['Gia'].toDouble() : json['Gia'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenMonAn': tenMonAn,
      'hinhAnh': hinhAnh,
      'gia': gia,
    };
  }
}

