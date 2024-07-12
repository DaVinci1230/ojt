import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojt/screens_user/uploading/uploader_hompage.dart';
import 'package:ojt/widgets/navbar.dart';
import '../../admin_screens/notifications.dart';
import '../../models/user_transaction.dart';
import 'user_menu.dart';
import 'user_upload.dart';
import 'no_support.dart';
import 'user_add_attachment.dart';
import 'view_files.dart';

class UserSendAttachment extends StatefulWidget {
  final Transaction transaction;
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
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
          MaterialPageRoute(builder: (context) => const UserMenuWindow()),
        );
        break;
    }
  }

  Future<void> _uploadTransactionOrFile() async {
    if (widget.transaction != null && widget.attachments != null) {
      setState(() {
        _isLoading = true;
      });

      bool allUploadedSuccessfully = true;
      List<String> errorMessages = [];

      try {
        var uri = Uri.parse(
            'http://192.168.131.94/localconnect/UserUploadUpdate/update_u.php');

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

                if (responseBody.startsWith('{') &&
                    responseBody.endsWith('}')) {
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
    } else {
      developer.log('Error: widget.transaction or attachments is null');
      _showDialog(
          context, 'Error', 'Error uploading file. Please try again later.');
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
