import 'package:flutter/material.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    String routeName;
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/translation_mode';
        break;
      case 2:
        routeName = '/explain_mode';
        break;
      case 3:
        routeName = '/history_saved';
        break;
      case 4:
        routeName = '/assistant_mode';
        break;
      default:
        routeName = '/home';
    }

    // Use pushReplacementNamed for main navigation to keep the history clean
    // or just pushNamed if we want to allow "back" to previous tab.
    // Given the request "add this footer in all 5 main pages", 
    // it functions as a primary navigation hub.
    if (index == 0) {
      // If going to Home, pop all routes until Home
      Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.slate900,
      selectedItemColor: AppColors.blue500,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.translate_rounded),
          label: 'Translate',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_rounded),
          label: 'Explain',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'Records',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_rounded),
          label: 'Assistant',
        ),
      ],
    );
  }
}
