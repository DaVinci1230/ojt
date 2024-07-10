import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojt/transmittal_screens/no_support_transmit.dart';
import '/screens_user/no_support.dart';
import 'package:http/http.dart' as http;


import '../admin_screens/notifications.dart';
import '../models/user_transaction.dart';
import '../screens_user/user_menu.dart';
import 'fetching_transmital_data.dart';
import 'transmitter_homepage.dart';

class NoSupportTransmitDetails extends StatefulWidget {
  final Transaction transaction;
  final List<String> selectedDetails;

  NoSupportTransmitDetails({
    Key? key,
    required this.transaction,
    required this.selectedDetails, required List attachments,
  }) : super(key: key);

  @override
  _NoSupportTransmitDetailsState createState() => _NoSupportTransmitDetailsState();
}

String createDocRef(String docType, String docNo) {
  return '$docType#$docNo';
}

class _NoSupportTransmitDetailsState extends State<NoSupportTransmitDetails> {
  int _selectedIndex = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
          MaterialPageRoute(builder: (context) => const TransmittalHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NoSupportScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuWindow()),
        );
        break;
    }
  }
    void _navigateToTransmitterHomePage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const TransmitterHomePage(key: Key('value')),
    ),
  );
}
  Future<void> _uploadTransaction() async {
  setState(() {
    _isLoading = true; // Show loading indicator
  });

  try {
    var uri = Uri.parse('http://127.0.0.1/localconnect/UserUploadUpdate/transmitter/update_ops_tnd.php');
    var request = http.Request('POST', uri);

    // URL-encode the values
    var requestBody = 'doc_type=${Uri.encodeComponent(widget.transaction.docType)}&doc_no=${Uri.encodeComponent(widget.transaction.docNo)}&date_trans=${Uri.encodeComponent(widget.transaction.dateTrans)}';

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body = requestBody;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Transaction upload failed with status: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error uploading transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Error uploading transaction. Please try again later.')),
    );
  } finally {
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }
}

  Widget buildDetailsCard(Transaction detail) {
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
              buildReadOnlyTextField('Transacting Party', detail.transactingParty),
              SizedBox(height: 20),
              buildTable(detail),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _uploadTransaction();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>NoSupportTransmit(key: Key('value')),
                              ),
                            );
                          },
                    icon: Icon(Icons.send),
                    label: Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 79, 129, 189),
                    ),
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

  Widget buildTable(Transaction detail) {
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
    buildTableRow('Status', detail.transactionStatusWord), // Use the getter here
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
                  'logo.png',
                  width: 60,
                  height: 55,
                ),
                const SizedBox(width: 8),
                const Text(
                  'For Transmittal',
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
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(),
                        ),
                      );
                    },
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