import 'package:flutter/material.dart';

import '../../core/storage/session_manager.dart';
import '../../data/service/music_service/music_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/mini_player.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'library_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  String _userName = "";
  String _photoUrl = "";
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await SessionManager.getDataUSerLogin();
    if (mounted) {
      setState(() {
        _userName = user['username'] ?? '';
        _photoUrl = user['photo_url'] ?? '';
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize pages with current user data
    final pages = [
      const HomePage(),
      const SearchPage(),
      const LibraryPage(),
      ProfilePage(userName: _userName, photoUrl: _photoUrl),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _currentIndex, children: pages),

          Positioned(
            left: 0,
            right: 0,
            bottom: 95,
            child: ListenableBuilder(
              listenable: MusicService.instance,
              builder: (context, _) {
                final track = MusicService.instance.currentTrack;

                if (track == null) {
                  return const SizedBox.shrink();
                }

                return const MiniPlayer();
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavPill(
              image: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
              selectedIndex: _currentIndex,
              onTabChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }
}
