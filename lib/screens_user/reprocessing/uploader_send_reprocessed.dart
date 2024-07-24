import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import '../uploader_notification.dart';
import '../uploading/user_menu.dart';
import 'dart:developer' as developer;
import '../../models/user_transaction.dart';
import '../../transmittal_screens/rep_view_files.dart';
import '../../transmittal_screens/transmitter_homepage.dart';
import '../../transmittal_screens/uploader_menu.dart';
import '../../api_services/api_services.dart';
import 'user_reprocessing_add_attachment.dart';



class UploaderRepSendAttachment extends StatefulWidget {
  final UserTransaction transaction;
  final List<Map<String, String>> attachments;
  
  UploaderRepSendAttachment(
      {Key? key,
      required this.transaction,
      required this.attachments,
      required List selectedDetails})
      : super(key: key) {}

  @override
  _UploaderRepSendAttachmentState createState() => _UploaderRepSendAttachmentState();
}

class _UploaderRepSendAttachmentState extends State<UploaderRepSendAttachment> {
  int _selectedIndex = 0;
  bool _isLoading = false;
   int notificationCount = 0; 
    final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
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
           transaction.onlineProcessingStatus == 'R' 
                 &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransmitterHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UploaderMenuWindow()),
        );
        break;
    }
  }
  

  Future<void> _uploadTransactionOrFile() async {
  setState(() {
    _isLoading = true;
  });

  try {
    var result = await _apiService .uploadTransactionOrFile(
      docType: widget.transaction.docType.toString(),
      docNo: widget.transaction.docNo.toString(),
      dateTrans: widget.transaction.dateTrans.toString(),
      attachments: widget.attachments.toList(),
      
    );

    if (result['success']) {
      setState(() {
        // Update attachments and secAttachments statuses if needed
      });

      _showDialog(context, 'Success', result['message']);
    } else {
      _showDialog(context, 'Error', 'Error uploading files:\n${result['message']}');
    }
  } catch (e) {
    developer.log('Error uploading file or transaction: $e');
    _showDialog(context, 'Error', 'Error uploading file. Please try again later.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget buildDetailsCard(UserTransaction detail) {
    return Container(
      height: 420,
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
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 79, 128, 189),
        toolbarHeight: 77,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                    IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UploaderRepAddAttachments(
                    transaction: widget.transaction,
                    selectedDetails: [],
                  ),
                ),
              );
            },
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
                              builder: (context) => UserMenuWindow()),
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
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RepViewFiles(
                              docType: widget.transaction.docType,
                              docNo: widget.transaction.docNo,
                              attachments: widget.attachments,
                              onDelete: (int index) {
                                setState(() {
                                  widget.attachments.removeAt(index);
                                });
                                developer.log(
                                    'Attachment removed from UserSendAttachment: $index');
                              },
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
                              _uploadTransactionOrFile();
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         fetchUpload(key: Key('value')),
                              //   ),
                              // );
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
