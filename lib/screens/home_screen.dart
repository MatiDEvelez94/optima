import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_tab.dart';
import 'profile_screen.dart';

// Marco de la app con la barra de navegación de abajo:
// casita = Inicio, tres rayitas = Perfil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [HomeTab(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navyLight,
        selectedItemColor: AppColors.cream,
        unselectedItemColor: AppColors.cream.withValues(alpha: 0.55),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 30),
            activeIcon: Icon(Icons.home, size: 30),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, size: 30),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}