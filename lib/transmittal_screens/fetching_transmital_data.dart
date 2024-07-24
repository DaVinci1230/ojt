import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/transmittal_screens/no_support_transmit.dart';

import 'package:scrollable_table_view/scrollable_table_view.dart';

import '../models/user_transaction.dart';
import '../widgets/table.dart';
import 'review_data.dart';
import 'transmittal_notification.dart';
import 'transmitter_menu.dart';
import 'transmitter_homepage.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '/api_services/transmitter_api.dart';

class TransmittalHomePage extends StatefulWidget {
  const TransmittalHomePage({Key? key}) : super(key: key);

  @override
  _TransmittalHomePageState createState() => _TransmittalHomePageState();
}

class _TransmittalHomePageState extends State<TransmittalHomePage> {
  late List<UserTransaction> transactions;
  late bool isLoading;
  String selectedColumn = 'docRef';
  List<String> headers = ['Doc Ref', 'Payor', 'Amount'];
  bool isAscending = true;
  int currentPage = 1;
  int rowsPerPage = 20;
  int _selectedIndex = 0;
  int notificationCount = 0;
  final TransmitterAPI _apiService = TransmitterAPI();


  @override
  void initState() {
    super.initState();
    isLoading = true;
    transactions = [];
    fetchTransactions();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransmitterHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NoSupportTransmit()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransmitMenuWindow()),
        );
        break;
    }
  }


    Future<void> _countNotif() async {
    try {
      List<UserTransaction> transactions = await _apiService.countNotification();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
                transaction.onlineProcessingStatus == 'TND' ||
                transaction.onlineProcessingStatus == 'T' &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }




  void _navigateToTransmitterHomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransmitterHomePage(key: Key('value')),
      ),
    );
  }

   Future<void> fetchTransactions() async {
  setState(() {
    isLoading = true;
  });

  try {
    List<UserTransaction> fetchedTransactions = await TransmitterAPI().fetchTransactionsTransmit();
    setState(() {
      transactions = fetchedTransactions;
      isLoading = false;
    });
  } catch (e) {
    print('Error fetching data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to fetch transactions: $e'),
        duration: Duration(seconds: 5),
      ),
    );
    setState(() {
      isLoading = false;
    });
  }
}


  void previousPage() {
    setState(() {
      if (currentPage > 1) currentPage--;
    });
  }

  void nextPage() {
    setState(() {
      if ((currentPage + 1) * rowsPerPage <= transactions.length) currentPage++;
    });
  }

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('MM/dd/yy');
    return formatter.format(date);
  }

  String formatAmount(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_PH', // Filipino locale
      symbol: '₱', // Currency symbol for Philippine Peso
      decimalDigits: 2, // Number of decimal places
    );
    return currencyFormat.format(amount);
  }

  String createDocRef(String docType, String docNo, DateTime transDate) {
    final String formattedDate = formatDate(transDate);
    return 'Ref: $docType#$docNo; $formattedDate';
  }

  void sortTransactions(String columnName) {
    setState(() {
      if (selectedColumn == columnName) {
        isAscending = !isAscending;
      } else {
        selectedColumn = columnName;
        isAscending = true;
      }

      switch (columnName) {
        case 'Doc Ref':
          transactions.sort((a, b) {
            final String docRefA =
                createDocRef(a.docType, a.docNo, a.transDate);
            final String docRefB =
                createDocRef(b.docType, b.docNo, b.transDate);
            return isAscending
                ? docRefA.compareTo(docRefB)
                : docRefB.compareTo(docRefA);
          });
          break;
        case 'Payor':
          transactions.sort((a, b) => isAscending
              ? a.transactingParty.compareTo(b.transactingParty)
              : b.transactingParty.compareTo(a.transactingParty));
          break;
        case 'Amount':
          transactions.sort((a, b) => isAscending
              ? a.checkAmount.compareTo(b.checkAmount)
              : b.checkAmount.compareTo(a.checkAmount));
          break;
      }
    });
  }

  void navigateToDetails(UserTransaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewData(
          transaction: transaction,
          selectedDetails: [],
          attachments: [], // Adjust based on your requirements
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final paginatedTransactions = transactions
        .skip((currentPage - 1) * rowsPerPage)
        .take(rowsPerPage)
        .toList();

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
                IconButton(
                  onPressed: () => _navigateToTransmitterHomePage(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 55,
                ),
                const SizedBox(width: 8),
                const Text(
                  'For Transmittal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: screenSize.width * 0.02),
                      child: badges.Badge(
                        badgeContent: Text(
                          notificationCount > 0 ? '$notificationCount' : '',
                          style: TextStyle(color: Colors.white),
                        ),
                        badgeStyle: BadgeStyle(
                          badgeColor: notificationCount > 0
                              ? Colors.red
                              : Colors.transparent,
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
                              builder: (context) => TransmitMenuWindow()),
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


          ],
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                          color: Color.fromARGB(255, 79, 128, 189),
                          strokeAlign: BorderSide.strokeAlignOutside,
                          width: 2.0),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ScrollableTableViewWidget(
                                  headers: headers,
                                  transactions: paginatedTransactions,
                                  onRowTap: navigateToDetails,
                                  rows: [],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 79, 128, 189),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Transmit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'No Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
