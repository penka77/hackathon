import 'package:flutter/material.dart';
import 'src/sale.dart';
import 'src/check.dart';
import 'src/stat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Стартовая страница - статистика (центральная)

  final List<Widget> _screens = [
    const SaleScreen(),
    const CheckScreen(),
    const StatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFE46666),
        unselectedItemColor: const Color(0xFFFD8181),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: Colors.black),
            label: 'Продажи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt, color: Colors.black),
            label: 'Чеки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, color: Colors.black),
            label: 'Статистика',
          ),
        ],
        backgroundColor: Colors.white,
      ),
    );
  }
}