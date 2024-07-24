
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api_services/api_services.dart';
import '../../transmittal_screens/homepage_menu.dart';

import '../uploader_notification.dart';
import '/screens_user/uploading/user_upload.dart';

import '/widgets/navbar.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '../../models/user_transaction.dart';
import 'user_add_attachment.dart';
import 'user_menu.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 

class DisbursementDetailsScreen extends StatefulWidget {
  final UserTransaction transaction;
  final List<String> selectedDetails;
  final bool isReprocessing;
  int notificationCount = 0;

  DisbursementDetailsScreen(
      {Key? key,
      required this.transaction,
      required this.selectedDetails,
      this.isReprocessing = false})
      : super(key: key);

  _DisbursementDetailsScreenState createState() =>
      _DisbursementDetailsScreenState();
}

String createDocRef(String docType, String docNo) {
  return '$docType#$docNo';
}

class _DisbursementDetailsScreenState extends State<DisbursementDetailsScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _countNotif();
  }

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    return formatter.format(date);
  }

  String formatAmount(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    return currencyFormat.format(amount);
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
          MaterialPageRoute(builder: (context) => const HomePage()),
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

Future<void> _countNotif() async {
    try {
      List<UserTransaction> transactions = await _apiService.fetchTransactionDetails();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
           transaction.onlineProcessingStatus == 'U' ||
           transaction.onlineProcessingStatus == 'ND' ||
           transaction.onlineProcessingStatus == 'R' ||
                transaction.onlineProcessingStatus == 'TND' ||
                transaction.onlineProcessingStatus == 'T' &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  Future<void> _uploadTransaction() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      await ApiService().uploadTransaction(
        widget.transaction.docType,
        widget.transaction.docNo,
        widget.transaction.dateTrans,
      );

      // If upload succeeds, show success message and possibly navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction uploaded successfully'),
        ),
      );
      Navigator.pop(context); // Navigate back assuming this is a modal or page
    } catch (e) {
      // Handle error cases
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload transaction: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Widget buildDetailsCard(UserTransaction detail) {
    return Container(
      child: Card(
        semanticContainer: true,
        borderOnForeground: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildReadOnlyTextField(
                  'Transacting Party', detail.transactingParty),
              SizedBox(height: 20),
              buildTable(detail),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserAddAttachment(
                              transaction: detail,
                              selectedDetails: [],
                            ),
                          ),
                        );
                      },
                      child: Text('Add Attachment'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color.fromARGB(255, 79, 128, 189),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 10), // Add some spacing between the buttons
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _uploadTransaction();
                            },
                      icon: Icon(Icons.send),
                      label: Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 79, 129, 189),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReadOnlyTextField(String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 90, 119, 154)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      readOnly: true,
    );
  }

  Widget buildTable(UserTransaction detail) {
    return Table(
      columnWidths: {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        width: 1.0,
        color: Colors.black,
      ),
      children: [
        buildTableRow('Doc Ref', createDocRef(detail.docType, detail.docNo)),
        buildTableRow('Date', formatDate(detail.transDate)),
        buildTableRow('Payee', detail.transactingParty),
        buildTableRow('Check', detail.checkNumber),
        buildTableRow('Bank', detail.bankName),
        buildTableRow('Amount', formatAmount(detail.checkAmount)),
        buildTableRow('Status', detail.transactionStatusWord),
        buildTableRow('Remarks', detail.remarks),
      ],
    );
  }

  TableRow buildTableRow(String label, String value) {
    return TableRow(
      children: [
        buildTableCell(label),
        buildTableCell(value),
      ],
    );
  }

  Widget buildTableCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tahoma',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

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
                    fontFamily: 'Tahoma',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildDetailsCard(widget.transaction),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
