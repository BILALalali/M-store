import 'package:flutter/material.dart';

class OtherServicesScreen extends StatelessWidget {
  const OtherServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ألوان الهوية البصرية
    const Color turquoise = Color(0xFF6FD8E8);
    const Color turquoiseDark = Color(0xFF3EC6D3);
    const Color beige = Color(0xFFFAF6EF);
    final services = [
      {
        'title': 'تواصل معنا',
        'icon': Icons.support_agent,
        'color': turquoise,
        'route': '/service1',
      },
      {
        'title': 'تحويل رصيد',
        'icon': Icons.swap_horiz,
        'color': turquoiseDark,
        'route': '/service2',
      },
      {
        'title': 'خدمات التوصيل',
        'icon': Icons.local_shipping,
        'color': turquoise,
        'route': '/service3',
      },
      {
        'title': 'شحن كروت ألعاب',
        'icon': Icons.videogame_asset,
        'color': turquoiseDark,
        'route': '/service4',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمات أخرى'),
        centerTitle: true,
        backgroundColor: turquoise,
        elevation: 0,
      ),
      backgroundColor: beige,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - 56) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: services.map((service) {
                return Material(
                  color: service['color'] as Color,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.pushNamed(context, service['route'] as String);
                    },
                    child: Container(
                      width: cardWidth < 160 ? 160 : cardWidth,
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            service['icon'] as IconData,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            service['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class OtherServicePlaceholderScreen extends StatelessWidget {
  final String title;
  const OtherServicePlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'صفحة $title (تحت الإنشاء)',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
