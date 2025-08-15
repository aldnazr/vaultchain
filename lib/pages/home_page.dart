import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'history_page.dart';
import 'market_tab.dart';
import 'profile_page.dart';
import 'wallet_tab.dart';
import 'trade_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    MarketTab(),
    TradeTab(),
    WalletTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Crypto App';
    if (_selectedIndex == 0) {
      title = 'Dashboard';
    } else if (_selectedIndex == 1) {
      title = 'Market';
    } else if (_selectedIndex == 2) {
      title = 'Trade';
    } else if (_selectedIndex == 3) {
      title = 'Wallet';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: const Color.fromARGB(255, 59, 160, 63),
            fontFamily: 'SFPRODISPLAY',
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            color: Color.fromARGB(255, 59, 160, 63),
            tooltip: 'History',
            onPressed: () {
              _navigateToHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_2_outlined),
            color: Color.fromARGB(255, 59, 160, 63),
            onPressed: () {
              _navigateToProfile(context);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: SizedBox(
          height: 80,
          child: BottomNavigationBar(
            iconSize: 30,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.analytics_outlined,
                ),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz_outlined),
                label: 'Trade',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.wallet_outlined,
                ),
                label: 'Wallet',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Color.fromARGB(255, 59, 160, 63),
            backgroundColor: Colors.transparent,
            unselectedItemColor: const Color.fromARGB(255, 184, 184, 184),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
