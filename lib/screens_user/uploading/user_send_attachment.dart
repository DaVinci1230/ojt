import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../uploader_notification.dart';
import '/screens_user/uploading/uploader_hompage.dart';
import '/widgets/navbar.dart';
import '../../models/user_transaction.dart';
import 'user_menu.dart';
import 'user_upload.dart';
import 'user_add_attachment.dart';
import 'view_files.dart';
import '../../api_services/api_services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 
import 'dart:convert';
import 'dart:typed_data';

class UserSendAttachment extends StatefulWidget {
  final UserTransaction transaction;
  final List selectedDetails;
  final List<Map<String, String>> attachments;

  const UserSendAttachment({
    Key? key,
    required this.transaction,
    required this.selectedDetails,
    required this.attachments,
  }) : super(key: key);

  @override
  _UserSendAttachmentState createState() => _UserSendAttachmentState();
}

class _UserSendAttachmentState extends State<UserSendAttachment> {
  int _selectedIndex = 0;
  bool _showRemarks = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
 int notificationCount = 0;
  List<Map<String, String>> attachments = [];

  @override
  void initState() {
    super.initState();
    attachments = widget.attachments;
    _countNotif();
  }

  // Function to convert image file to Base64
Future<String> convertImageToBase64(Uint8List imageBytes) async {
  return base64Encode(imageBytes);
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
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      // case 1:
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const NoSupportScreen()),
      //   );
      //   break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserMenuWindow()),
        );
        break;
    }
  }

  Future<void> _uploadTransactionOrFile() async {
  if (widget.transaction != null && widget.attachments != null && widget.attachments.isNotEmpty) {
    setState(() {
      _isLoading = true;
    });

    try {
      var result = await ApiService().uploadTransactionAndFiles(
        docType: widget.transaction.docType.toString(),
        docNo: widget.transaction.docNo.toString(),
        dateTrans: widget.transaction.dateTrans.toString(),
        attachments: widget.attachments.toList(),
      );

      if (result['success']) {
        setState(() {
          widget.attachments.forEach((attachment) {
            attachment['status'] = 'Uploaded';
          });
          developer.log('Attachments array after uploading: ${widget.attachments}');
        });

        _showDialog(context, 'Success', result['message']);
      } else {
        _showDialog(context, 'Error', result['message']);
        developer.log('Error uploading files: ${result['message']}');
      }
    } catch (e) {
      developer.log('Error uploading file or transaction: $e');
      _showDialog(context, 'Error', 'Error uploading file. Please try again later.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  } else {
    developer.log('Error: widget.transaction or attachments is null or empty');
    _showDialog(context, 'Error', 'No transaction or attachments to upload.');
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
              Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserAddAttachment(
                                transaction: detail,
                                selectedDetails: [],
                              )),
                    );

                    if (result != null && result is List<Map<String, String>>) {
                      setState(() {
                        widget.attachments.addAll(result);
                      });
                    }
                  },
                  child: Text('Add Attachment'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color.fromARGB(255, 79, 128, 189),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            builder: (context) => ViewFilesPage(
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UploaderHomePage(key: Key('value')),
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
