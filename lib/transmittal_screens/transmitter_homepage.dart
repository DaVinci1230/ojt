import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'fetch_reprocessing.dart';
import 'fetching_uploader_data.dart';
import 'fetching_transmital_data.dart';
import 'homepage_menu.dart';
import '../models/user_transaction.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  Future<void> _fetchTransactionDetails() async {
    try {
      var url =
          Uri.parse('http://127.0.0.1/localconnect/count_transaction.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> fetchedTransactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
              .toList();
          fetchedTransactions
              .sort((a, b) => b.transDate.compareTo(a.transDate));

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
                .where((transaction) => transaction.transactionStatus == 'R' &&
                transaction.onlineProcessingStatus == '')
                .length;
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load transaction details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
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
    final screenSize = MediaQuery.of(context).size;

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
                  'logo.png',
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
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
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
