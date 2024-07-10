import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import '../admin_screens/notifications.dart';
import '../models/user_transaction.dart';
import '../transmittal_screens/transmitter_homepage.dart';
import 'fetching_uploader_data.dart';
import 'transmitterSecondAttachment.dart';
import 'uploader_menu.dart';
import 'uploader_viewfiles.dart'; // Import your TransmitView widget here
import 'no_support_transmit.dart';

class TransmitterSendAttachment extends StatefulWidget {
  final Transaction transaction;
  final List<Map<String, String>> attachments;
  final List<Map<String, String>> secAttachments;

  TransmitterSendAttachment(
      {Key? key,
      required this.transaction,
      required this.attachments,
      required List selectedDetails,
      required this.secAttachments})
      : super(key: key) {
  }

  @override
  _TransmitterSendAttachmentState createState() =>
      _TransmitterSendAttachmentState();
}

class _TransmitterSendAttachmentState extends State<TransmitterSendAttachment> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    //developer.log('TransmitterSendAttachment initState: secAttachments = ${widget.secAttachments}');
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
          MaterialPageRoute(builder: (context) => const NoSupportTransmit()),
        );
        break;
      case 2:
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

    bool allUploadedSuccessfully = true;
    List<String> errorMessages = [];

    try {
      var uri = Uri.parse(
          'http://127.0.0.1/localconnect/UserUploadUpdate/update_u.php');

      // Process attachments
      for (var attachment in widget.attachments.toList()) {
        if (attachment['name'] != null &&
            attachment['bytes'] != null &&
            attachment['size'] != null) {
          var request = http.MultipartRequest('POST', uri);

          request.fields['doc_type'] = widget.transaction.docType.toString();
          request.fields['doc_no'] = widget.transaction.docNo.toString();
          request.fields['date_trans'] =
              widget.transaction.dateTrans.toString();

          var pickedFile = PlatformFile(
            name: attachment['name']!,
            bytes: Uint8List.fromList(utf8.encode(attachment['bytes']!)),
            size: int.parse(attachment['size']!),
          );

          if (pickedFile.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                pickedFile.bytes!,
                filename: pickedFile.name,
              ),
            );

            developer.log('Uploading file: ${pickedFile.name}');

            var response = await request.send();

            if (response.statusCode == 200) {
              var responseBody = await response.stream.bytesToString();
              developer.log('Upload response: $responseBody');

              if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
                var result = jsonDecode(responseBody);

                if (result['status'] == 'success') {
                  setState(() {
                    widget.attachments.removeWhere(
                        (element) => element['name'] == pickedFile.name);
                    widget.attachments
                        .add({'name': pickedFile.name, 'status': 'Uploaded'});
                    developer.log(
                        'Attachments array after uploading: ${widget.attachments}');
                  });
                } else {
                  allUploadedSuccessfully = false;
                  errorMessages.add(result['message']);
                  developer.log('File upload failed: ${result['message']}');
                }
              } else {
                allUploadedSuccessfully = false;
                errorMessages.add('Invalid response from server');
                developer.log('Invalid response from server: $responseBody');
              }
            } else {
              allUploadedSuccessfully = false;
              errorMessages.add(
                  'File upload failed with status: ${response.statusCode}');
              developer.log(
                  'File upload failed with status: ${response.statusCode}');
            }
          } else {
            allUploadedSuccessfully = false;
            errorMessages.add('Error: attachment bytes are null or empty');
            developer.log('Error: attachment bytes are null or empty');
          }
        } else {
          allUploadedSuccessfully = false;
          errorMessages.add('Error: attachment name, bytes or size is null');
          developer.log('Error: attachment name, bytes or size is null');
        }
      }

      // Process secAttachments
      for (var secAttachment in widget.secAttachments.toList()) {
        if (secAttachment['name'] != null &&
            secAttachment['bytes'] != null &&
            secAttachment['size'] != null) {
          var request = http.MultipartRequest('POST', uri);

          request.fields['doc_type'] = widget.transaction.docType.toString();
          request.fields['doc_no'] = widget.transaction.docNo.toString();
          request.fields['date_trans'] =
              widget.transaction.dateTrans.toString();

          var pickedFile = PlatformFile(
            name: secAttachment['name']!,
            bytes: Uint8List.fromList(utf8.encode(secAttachment['bytes']!)),
            size: int.parse(secAttachment['size']!),
          );

          if (pickedFile.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                pickedFile.bytes!,
                filename: pickedFile.name,
              ),
            );

            developer.log('Uploading file: ${pickedFile.name}');

            var response = await request.send();

            if (response.statusCode == 200) {
              var responseBody = await response.stream.bytesToString();
              developer.log('Upload response: $responseBody');

              if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
                var result = jsonDecode(responseBody);

                if (result['status'] == 'success') {
                  setState(() {
                    widget.secAttachments.removeWhere(
                        (element) => element['name'] == pickedFile.name);
                    widget.secAttachments
                        .add({'name': pickedFile.name, 'status': 'Uploaded'});
                    developer.log(
                        'secAttachments array after uploading: ${widget.secAttachments}');
                  });
                } else {
                  allUploadedSuccessfully = false;
                  errorMessages.add(result['message']);
                  developer.log('File upload failed: ${result['message']}');
                }
              } else {
                allUploadedSuccessfully = false;
                errorMessages.add('Invalid response from server');
                developer.log('Invalid response from server: $responseBody');
              }
            } else {
              allUploadedSuccessfully = false;
              errorMessages.add(
                  'File upload failed with status: ${response.statusCode}');
              developer.log(
                  'File upload failed with status: ${response.statusCode}');
            }
          } else {
            allUploadedSuccessfully = false;
            errorMessages.add('Error: attachment bytes are null or empty');
            developer.log('Error: attachment bytes are null or empty');
          }
        } else {
          allUploadedSuccessfully = false;
          errorMessages.add('Error: attachment name, bytes or size is null');
          developer.log('Error: attachment name, bytes or size is null');
        }
      }

      if (allUploadedSuccessfully) {
        _showDialog(context, 'Success', 'All files uploaded successfully!');
      } else {
        _showDialog(context, 'Error',
            'Error uploading files:\n${errorMessages.join('\n')}');
      }
    } catch (e) {
      developer.log('Error uploading file or transaction: $e');
      _showDialog(
          context, 'Error', 'Error uploading file. Please try again later.');
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

  Widget buildDetailsCard(Transaction detail) {
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
                  'logo.png',
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
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationScreen()),
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UploaderMenuWindow()),
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
                            builder: (context) => TransmitView(
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
                                      fetchUpload(key: Key('value')),
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