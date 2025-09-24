import 'package:flutter/material.dart';
import 'mobile_credit_screen.dart';
import 'game_cards_screen.dart';
import 'chat_screen.dart';
import '../../core/services/support_chat_service.dart';
import 'dart:async';

class OtherServicesScreen extends StatefulWidget {
  const OtherServicesScreen({super.key});

  @override
  State<OtherServicesScreen> createState() => _OtherServicesScreenState();
}

class _OtherServicesScreenState extends State<OtherServicesScreen> {
  int _unreadMessagesCount = 0;
  StreamSubscription? _unreadSubscription;

  // ألوان الهوية البصرية - نقلها خارج build method
  static const Color _tertiaryColor = Color(0xFF00CED1);
  static const Color _backgroundColor = Color.fromARGB(255, 241, 240, 235);
  static const Color _overlayColor = Color.fromARGB(41, 240, 234, 208);

  // قائمة الخدمات - نقلها خارج build method
  List<Map<String, dynamic>> get _services => [
    {
      'title': 'تواصل معنا', 
      'icon': Icons.support_agent, 
      'route': '/chat',
      'unreadCount': _unreadMessagesCount,
    },
    {
      'title': 'تحويل رصيد الجوال',
      'icon': Icons.phone_android,
      'route': '/mobile-credit',
      'unreadCount': 0,
    },
    {
      'title': 'خدمات التوصيل',
      'icon': Icons.local_shipping,
      'route': '/service3',
      'unreadCount': 0,
    },
    {
      'title': 'شحن كروت ألعاب',
      'icon': Icons.videogame_asset,
      'route': '/game-cards',
      'unreadCount': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeUnreadCount();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUnreadCount() async {
    // جلب العدد الأولي
    final count = await SupportChatService.getUnreadMessagesCount();
    if (mounted) {
      setState(() {
        _unreadMessagesCount = count;
      });
    }

    // الاشتراك في التحديثات
    _unreadSubscription = await SupportChatService.subscribeToUnreadCount((count) {
      if (mounted) {
        setState(() {
          _unreadMessagesCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tertiaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _tertiaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(Icons.widgets, color: _tertiaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'خدمات أخرى',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // خلفية بسيطة
        Container(color: _overlayColor),
        // المحتوى الرئيسي
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return ServiceCard(
                      title: service['title'] as String,
                      icon: service['icon'] as IconData,
                      unreadCount: service['unreadCount'] as int,
                      onTap: () {
                        if (service['route'] == '/mobile-credit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MobileCreditScreen(),
                            ),
                          );
                        } else if (service['route'] == '/game-cards') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GameCardsScreen(),
                            ),
                          );
                        } else if (service['route'] == '/chat') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatScreen(),
                            ),
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            service['route'] as String,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int unreadCount;
  final VoidCallback onTap;

  static const Color _tertiaryColor = Color(0xFF00CED1);

  const ServiceCard({
    super.key,
    required this.title,
    required this.icon,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _tertiaryColor.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [_buildIconSection(), _buildButtonSection()]),
      ),
    );
  }

  Widget _buildIconSection() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          color: _tertiaryColor.withOpacity(0.08),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildIcon(), const SizedBox(height: 12), _buildTitle()],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      children: [
        Container(
          width: 91,
          height: 101,
          decoration: BoxDecoration(
            color: _tertiaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _tertiaryColor.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, size: 45, color: _tertiaryColor),
        ),
        // شارة الرسائل غير المقروءة
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildButtonSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        height: 32,
        decoration: BoxDecoration(
          color: _tertiaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _tertiaryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'استعراض',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}

class OtherServicePlaceholderScreen extends StatelessWidget {
  final String title;

  static const Color _backgroundColor = Color.fromARGB(183, 85, 130, 131);
  static const Color _appBarColor = Color.fromARGB(255, 143, 185, 194);
  static const Color _accentColor = Color(0xFFE91E63);

  const OtherServicePlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarColor,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconContainer(),
          const SizedBox(height: 24),
          _buildTitleText(),
          const SizedBox(height: 8),
          _buildSubtitleText(),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.3), width: 2),
      ),
      child: const Icon(Icons.construction, size: 64, color: Color(0xFFE91E63)),
    );
  }

  Widget _buildTitleText() {
    return Text(
      'صفحة $title',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildSubtitleText() {
    return const Text(
      'تحت الإنشاء',
      style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
    );
  }
}
