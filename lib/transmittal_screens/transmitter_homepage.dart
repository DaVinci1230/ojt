import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/transmittal_screens/transmittal_notification.dart';
import 'fetch_reprocessing.dart';
import 'fetching_uploader_data.dart';
import 'fetching_transmital_data.dart';
import 'homepage_menu.dart';
import '../models/user_transaction.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 

import '../../api_services/transmitter_api.dart';

class TransmitterHomePage extends StatefulWidget {
  const TransmitterHomePage({Key? key}) : super(key: key);

  @override
  _TransmitterHomePageState createState() => _TransmitterHomePageState();
}

class _TransmitterHomePageState extends State<TransmitterHomePage> {
  int _selectedIndex = 0;
  int _reprocessingCount = 0;
  int _transmittalCount = 0;
  int _uploadingCount = 0;
  bool isLoading = true;
  int notificationCount = 0; 
  final TransmitterAPI _apiService = TransmitterAPI();

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }


 void updateNotificationCount(int reprocessingCount, int transmittalCount, int uploadingCount) {
    setState(() {
      notificationCount = reprocessingCount + transmittalCount + uploadingCount;
      _reprocessingCount = reprocessingCount;
      _transmittalCount = transmittalCount;
      _uploadingCount = uploadingCount;
    });
  }

  void onNewTransactionReceived() async {
    final counts = await TransmitterAPI().fetchNewNotificationCount();
    updateNotificationCount(
      counts['reprocessingCount']!,
      counts['transmittalCount']!,
      counts['uploadingCount']!,
    );
  }

  Future<void> _fetchTransactionDetails() async {
    try {
      List<UserTransaction> fetchedTransactions = await TransmitterAPI().fetchTransactionDetails();

      setState(() {
        _reprocessingCount = fetchedTransactions
            .where((transaction) =>
                transaction.onlineProcessingStatus == 'R' &&
                transaction.transactionStatus == 'R')
            .length;
        _transmittalCount = fetchedTransactions
            .where((transaction) =>
                transaction.onlineProcessingStatus == 'U' ||
                transaction.onlineProcessingStatus == 'ND')
            .length;
        _uploadingCount = fetchedTransactions
            .where((transaction) =>
                transaction.transactionStatus == 'R' &&
                transaction.onlineProcessingStatus == '')
            .length;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch transaction details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transaction details: $e')),
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
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomepageMenuWindow()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 79, 128, 189),
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
                  'Dashboard',
                  style: TextStyle(
                    fontFamily: 'Tahoma', // Set font to Tahoma
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
                    '$notificationCount',  // Display the number of notifications
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
                            builder: (context) => TransmittalNotification()),
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
                        builder: (context) => const HomepageMenuWindow()),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
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
                              builder: (context) => FetchReprocess(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildDashboardCard(
                        screenSize,
                        title: 'For Transmittal',
                        count: '$_transmittalCount',
                        label: _plusS(_transmittalCount),
                        icon: Icons.history,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TransmittalHomePage(),
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
                              builder: (context) => const fetchUpload(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 110, 255),
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
          color: Color(0xFF4F80BD),
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
                    style: TextStyle(
                      fontFamily: 'Tahoma',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      children: [
                        Text(
                          count,
                          style: TextStyle(
                            fontFamily: 'Tahoma',
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
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
              margin: EdgeInsets.only(right: 10),
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
