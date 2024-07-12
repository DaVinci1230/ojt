import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_transaction.dart';
import '/admin_screens/view_attachments.dart';

class TransmitterCardNotification extends StatefulWidget {
  final Transaction transaction;

  const TransmitterCardNotification({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  _TransmitterCardNotificationState createState() => _TransmitterCardNotificationState();
}

class _TransmitterCardNotificationState extends State<TransmitterCardNotification>
    with SingleTickerProviderStateMixin {
  String? fileName;
  String? filePath;
  late AnimationController _controller;
  bool _showDetails = false;
  List<Map<String, dynamic>> _checkDetails = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fetchCheckDetails(widget.transaction.docNo, widget.transaction.docType);
    _fetchFileNameAndPath();
  }

  Future<void> _fetchCheckDetails(String docNo, String docType) async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.131.94/localconnect/view_details.php?doc_no=$docNo&doc_type=$docType'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _checkDetails = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        throw Exception('Failed to fetch check details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching check details: $e')),
        );
      } else {
        print('Error fetching check details: $e');
      }
    }
  }

  Future<void> _fetchFileNameAndPath() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.131.94/localconnect/get_file.php?doc_no=${widget.transaction.docNo}&doc_type=${widget.transaction.docType}'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            fileName = data['file_name'];
            filePath = data['file_path'];
          });
        }
      } else {
        throw Exception('Failed to fetch file details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching file details: $e')),
        );
      } else {
        print('Error fetching file details: $e');
      }
    }
  }

  Widget _buildCheckDetailsTable(List<Map<String, dynamic>> checkDetailsList) {
    List<TableRow> rows = [];
    void addTableRow(Map<String, dynamic> details, bool showDebit, int index) {
      String amountText = showDebit
          ? '${index == 0 ? '₱' : ''}${NumberFormat('#,###.##').format(double.parse(details['debit_amount']))} DR'
          : '${NumberFormat('#,###.##').format(double.parse(details['credit_amount']))} CR';

      rows.add(
        TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${details['acct_description'] ?? ''} / ${details['sl_description'] ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                amountText,
                style: TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }

    List<Map<String, dynamic>> debits = checkDetailsList
        .where((details) =>
            details.containsKey('debit_amount') &&
            details['debit_amount'] != null &&
            double.tryParse(details['debit_amount'].toString()) != null &&
            double.parse(details['debit_amount'].toString()) != 0)
        .toList();

    List<Map<String, dynamic>> credits = checkDetailsList
        .where((details) =>
            details.containsKey('credit_amount') &&
            details['credit_amount'] != null &&
            double.tryParse(details['credit_amount'].toString()) != null &&
            double.parse(details['credit_amount'].toString()) != 0)
        .toList();

    for (int i = 0; i < debits.length; i++) {
      addTableRow(debits[i], true, i);
    }
    for (int i = 0; i < credits.length; i++) {
      addTableRow(credits[i], false, i);
    }

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.005,
        ),
        Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.white),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blueAccent),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Account Description / SL Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            ...rows,
          ],
        ),
        SizedBox(
          height: 5,
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.005,
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (fileName != null && filePath != null)
                ElevatedButton.icon(
                  onPressed: _viewAttachments,
                  icon: Icon(Icons.attachment_rounded),
                  label: Text('View Attachment'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(12),
                    backgroundColor: Color.fromARGB(255, 187, 196, 204),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _viewAttachments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAttachments(
          docType: widget.transaction.docType,
          docNo: widget.transaction.docNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: _showDetails ? null : screenHeight * 0.345,
      child: Card(
        shadowColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        color: Color.fromARGB(255, 79, 98, 189),
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.015),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    width: screenWidth * 0.25,
                    child: Text(
                      "Ref:",
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(screenHeight * 0.006),
                      child: Text(
                        '${widget.transaction.docType}#${widget.transaction.docNo}; ${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.dateTrans))}',
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    width: screenWidth * 0.25,
                    child: Text(
                      "Pay to:",
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(screenHeight * 0.006),
                      child: Text(
                        widget.transaction.transactingParty,
                        style: TextStyle(
                          fontSize: screenHeight * 0.0115,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    width: screenWidth * 0.25,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'Amount: '),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(screenHeight * 0.006),
                      child: Text(
                        '₱${NumberFormat('#,##0.00').format(double.parse(widget.transaction.checkAm))}',
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    width: screenWidth * 0.25,
                    child: Text(
                      "Check Details:",
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(screenHeight * 0.006),
                      child: Text(
                        '${widget.transaction.checkNumber}; ${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.checkDate))}\n${widget.transaction.checkBankDrawee}',
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    width: screenWidth * 0.25,
                    child: Text(
                      "Remarks:",
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(screenHeight * 0.006),
                      child: Text(
                        widget.transaction.remarks,
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Container(
                width: screenWidth * 0.43,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 5),
                      width: screenWidth * 0.25,
                      child: Text(
                        "Status:",
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 227, 232, 235),
                        padding: EdgeInsets.all(screenHeight * 0.006),
                        child: Center(
                          child: Text(
                            widget.transaction.onlineProcessingStatusWord,
                            style: TextStyle(
                              fontSize: screenHeight * 0.014,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.007),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.005,
                      ),
                    ),
                    child: Text(
                      _showDetails ? 'Less' : 'More',
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: _showDetails
                    ? _buildCheckDetailsTable(_checkDetails)
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}