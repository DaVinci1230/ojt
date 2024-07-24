import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../uploader_notification.dart';
import '/widgets/navBar.dart';
import '/widgets/table.dart';
import '../../models/user_transaction.dart';
import 'disbursement_details.dart';
import 'uploader_hompage.dart';
import 'user_menu.dart'; 
import '../../api_services/api_services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<UserTransaction> transactions;
  late bool isLoading;
  String selectedColumn = 'docRef';
  List<String> headers = ['Doc Ref', 'Payor', 'Amount'];
  bool isAscending = true;
  int currentPage = 1;
   int notificationCount = 0;
  int rowsPerPage = 20;
  int _selectedIndex = 0; 
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    isLoading = true;
    transactions = [];
    fetchTransactions();
_countNotif();
  }

  
Future<void> _countNotif() async {
    try {
      List<UserTransaction> transactions = await _apiService.fetchTransactionDetails();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
           transaction.onlineProcessingStatus == 'U' ||
           transaction.onlineProcessingStatus == 'ND' ||
           transaction.onlineProcessingStatus == 'R'  &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
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
          MaterialPageRoute(builder: (context) => const UploaderHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserMenuWindow()),
        );
        break;
    }
  }

Future<void> fetchTransactions() async {
  setState(() {
    isLoading = true;
  });

  try {
    final transactionsData = await ApiService().fetchTransactions();
    
    setState(() {
      transactions = transactionsData
          .map((json) => UserTransaction.fromJson(json))
          .where((transaction) =>
              transaction.transactionStatus == 'R' &&
              transaction.onlineProcessingStatus == '')
          .toList();
      isLoading = false;
    });
  } catch (e) {
    print('Error fetching data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching data: $e')),
    );
    setState(() {
      isLoading = false;
    });
  }
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
        builder: (context) => DisbursementDetailsScreen(
          transaction: transaction,
          selectedDetails: [], // Adjust based on your requirements
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
                    'For Uploading',
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
        bottomNavigationBar:
            BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped));
  }
}
