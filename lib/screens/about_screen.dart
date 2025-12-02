import 'package:flutter/material.dart';
import 'dat_ban_screen.dart';
import 'menu_screen.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giới thiệu"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.amber.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VỀ VIET RESTAURANT",
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nâng tầm ẩm thực Việt bằng trải nghiệm tinh tế và đong đầy cảm xúc.",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chúng tôi kết hợp nguyên liệu bản địa với kỹ thuật hiện đại để tạo nên hành trình vị giác mới mẻ. Mỗi mùa, đội ngũ đầu bếp lại kể một câu chuyện khác về văn hóa Việt Nam qua từng món ăn.",
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DatBanScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Đặt bàn ngay"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MenuScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.deepPurple.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Khám phá thực đơn",
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("2015", "Năm thành lập"),
                _buildStatCard("120+", "Sự kiện riêng mỗi năm"),
                _buildStatCard("07", "Đầu bếp đạt giải"),
                _buildStatCard("12.000+", "Khách hàng thân thiết"),
              ],
            ),
            const SizedBox(height: 24),

            // Timeline
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hành trình phát triển",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildTimelineItem("2015", "Mở cửa cơ sở đầu tiên",
                        "Khởi đầu với mong muốn tôn vinh ẩm thực Việt hiện đại."),
                    _buildTimelineItem("2018", "Ra mắt thực đơn degustation",
                        "Kết hợp nguyên liệu bản địa với kỹ thuật fine-dining."),
                    _buildTimelineItem("2021", "Không gian rượu vang & lounge",
                        "Tạo trải nghiệm trọn vẹn từ món ăn đến thức uống."),
                    _buildTimelineItem("2024", "Chuỗi sự kiện chef table",
                        "Giới thiệu bộ sưu tập món mới theo mùa"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Values
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Giá trị chúng tôi hướng đến",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildValueCard("Tinh tế",
                        "Từng chi tiết được chăm chút: từ nhiệt độ món ăn đến âm nhạc, ánh sáng."),
                    const SizedBox(height: 12),
                    _buildValueCard("Địa phương",
                        "Ưu tiên nguyên liệu từ nông trại hữu cơ và làng nghề truyền thống."),
                    const SizedBox(height: 12),
                    _buildValueCard("Khách trung tâm",
                        "Trải nghiệm được cá nhân hóa theo dịp đặc biệt của từng vị khách."),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Experience Packages
            const Text(
              "Gói trải nghiệm",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildExperienceCard(
              "Private Dining",
              "Không gian riêng cho nhóm 8-20 khách với menu thiết kế riêng.",
              "Bao gồm hoa trang trí, quầy rượu và quản gia riêng.",
            ),
            const SizedBox(height: 12),
            _buildExperienceCard(
              "Chef Table",
              "Thực đơn 8 món theo mùa cùng tương tác trực tiếp từ bếp trưởng.",
              "Phù hợp kỷ niệm, cầu hôn hoặc tiếp khách cao cấp.",
            ),
            const SizedBox(height: 12),
            _buildExperienceCard(
              "Corporate Tasting",
              "Tiệc standing hoặc sit-down cho doanh nghiệp, tối đa 120 khách.",
              "Có gói âm thanh, ánh sáng, MC song ngữ.",
            ),
            const SizedBox(height: 24),

            // Quote Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "\"Mỗi thực khách đến Viet Restaurant đều là một câu chuyện. Chúng tôi muốn bạn cảm nhận được hơi thở của Việt Nam, dù bạn là người bản xứ hay đến từ phương xa.\"",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Founder Nguyễn Thảo Vy",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Cố vấn trải nghiệm khách hàng",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String year, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            child: Text(
              year,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(String title, String desc, String detail) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

