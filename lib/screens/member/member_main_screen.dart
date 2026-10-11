import 'package:flutter/material.dart';
import 'member_catalog_screen.dart';
import 'member_loan_list_screen.dart';

class MemberMainScreen extends StatefulWidget {
  const MemberMainScreen({super.key});

  @override
  State<MemberMainScreen> createState() => _MemberMainScreenState();
}

class _MemberMainScreenState extends State<MemberMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MemberCatalogScreen(),
    const MemberLoanListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Peminjaman',
          ),
        ],
      ),
    );
  }
}