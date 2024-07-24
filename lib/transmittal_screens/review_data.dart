import 'dart:convert';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojt/transmittal_screens/transmittal_notification.dart';
import '/transmittal_screens/no_support_transmit.dart';
import '/transmittal_screens/transmitter_menu.dart';
import '/transmittal_screens/view_attachment.dart';

import '../models/user_transaction.dart';
import 'fetching_transmital_data.dart';
import '../../api_services/transmitter_api.dart';
import 'view_attachment.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';


class ReviewData extends StatefulWidget {
  final UserTransaction transaction;
  final List selectedDetails;
  final List<Map<String, String>> attachments;

  const ReviewData({
    Key? key,
    required this.transaction,
    required this.selectedDetails,
    required this.attachments,
  }) : super(key: key);

  @override
  _ReviewDataState createState() => _ReviewDataState();
}

class _ReviewDataState extends State<ReviewData> {
  int _selectedIndex = 0;
  bool _isLoading = false;
   int notificationCount = 0; 
  final TransmitterAPI _apiService = TransmitterAPI();

  List<Map<String, String>> attachments = [];

  @override
  void initState() {
    super.initState();
    attachments = widget.attachments; // Initialize attachments list
  }

  String createDocRef(String docType, String docNo) {
    return '$docType#$docNo';
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
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const TransmittalHomePage()),
        // );
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


   Future<void> _uploadTransactionTransmitReview() async {
  setState(() {
    _isLoading = true; // Show loading indicator
  });

  try {
    var result = await TransmitterAPI().uploadTransactionTransmitReview(
      docType: widget.transaction.docType,
      docNo: widget.transaction.docNo,
      dateTrans: widget.transaction.dateTrans,
    );

    if (result['status'] == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );

      // Navigate back to previous screen (DisbursementDetailsScreen)
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  } catch (e) {
    print('Error uploading transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error uploading transaction. Please try again later.'),
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
      height: 450,
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
                'Attachments',
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
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          buildDetailsCard(widget.transaction),
          Spacer(), // Pushes the buttons to the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0), // Add some bottom padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                         MaterialPageRoute(
                      builder: (context) => ViewTransmit(
                        docType: widget.transaction.docType,
                        docNo: widget.transaction.docNo,
                      ),
                    ),
                      );
                    },
                    icon: Icon(Icons.folder_open),
                    label: Text('View Files'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _uploadTransactionTransmitReview();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransmittalHomePage(key: Key('value')),
                              ),
                            );
                          },
                    icon: Icon(Icons.reviews),
                    label: Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 79, 129, 189),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Color.fromARGB(255, 79, 128, 189),
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.upload_file_outlined),
          label: 'Upload',
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