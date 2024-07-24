
import 'package:flutter/material.dart';
import '../reprocessing/reprocessing.dart';
import '../../widgets/navBar.dart';
import '../uploader_notification.dart';
import 'user_menu.dart';
import 'user_upload.dart';
import '../../models/user_transaction.dart';
import '../../api_services/api_services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 

class UploaderHomePage extends StatefulWidget {
  const UploaderHomePage({Key? key}) : super(key: key);

  @override
  _UploaderHomePageState createState() => _UploaderHomePageState();
}

class _UploaderHomePageState extends State<UploaderHomePage> {
  int _selectedIndex = 0;
  int _reprocessingCount = 0;
  int _uploadingCount = 0;
   int notificationCount = 0;
  bool isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
    _countNotif();
  }

  Future<void> _countNotif() async {
    try {
      List<UserTransaction> transactions =
          await _apiService.fetchTransactionDetails();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
                transaction.onlineProcessingStatus == 'U' ||
                transaction.onlineProcessingStatus == 'ND' ||
                transaction.onlineProcessingStatus == 'R' &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  Future<void> _fetchTransactionDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<UserTransaction> fetchedTransactions =
          await ApiService().fetchTransactionDetails();

      setState(() {
        _reprocessingCount = fetchedTransactions
            .where((transaction) =>
                transaction.onlineProcessingStatus == 'R' &&
                transaction.transactionStatus == 'R')
            .length;

        _uploadingCount = fetchedTransactions
            .where((transaction) =>
                transaction.transactionStatus == 'R' &&
                transaction.onlineProcessingStatus == '')
            .length;

        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch transaction details: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  String _plusS(int pendingCount) {
    if (pendingCount > 1) {
      return 'Items';
    } else if (pendingCount == 1) {
      return 'Item';
    } else {
      return 'item';
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Do nothing or set a new state for the same page
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserMenuWindow()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 79, 128, 189),
        toolbarHeight: 77,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 55,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontFamily: 'Tahoma',
                    fontSize: 16,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(right: screenSize.width * 0.02),
                  child: badges.Badge(
                    badgeContent: Text(
                      '$notificationCount', // Display the number of notifications
                      style: TextStyle(color: Colors.white),
                    ),
                    badgeStyle: BadgeStyle(
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UploaderNotification()),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications,
                        size: 24,
                        color: Color.fromARGB(255, 233, 227, 227),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserMenuWindow()),
                    );
                  },
                  icon: const Icon(
                    Icons.person,
                    size: 24,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDashboardCard(
                  screenSize,
                  title: 'For Reprocessing',
                  count: '$_reprocessingCount',
                  label: _plusS(_reprocessingCount),
                  icon: Icons.content_paste,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Reprocess(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                _buildDashboardCard(
                  screenSize,
                  title: 'For Uploading',
                  count: '$_uploadingCount',
                  label: _plusS(_uploadingCount),
                  icon: Icons.upload_file,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardCard(Size screenSize,
      {required String title,
      required String count,
      required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 100,
        width: screenSize.width * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF4F80BD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tahoma',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      children: [
                        Text(
                          count,
                          style: const TextStyle(
                            fontFamily: 'Tahoma',
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Tahoma',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
