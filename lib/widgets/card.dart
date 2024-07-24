import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/admin_transaction.dart';
import '/admin_screens/view_attachments.dart';
import '/api_services/api_services_admin.dart';

class CustomCardExample extends StatefulWidget {
  final bool isSelected;
  final Transaction transaction;
  final Function(bool)? onSelectChanged;
  final ValueChanged<double>? onSelectedAmountChanged;
  final bool showSelectAllButton;
  final bool isSelectAll;
  final VoidCallback onResetTransactions;

  const CustomCardExample({
    Key? key,
    required this.transaction,
    required this.isSelected,
    required this.onSelectChanged,
    this.onSelectedAmountChanged,
    required this.showSelectAllButton,
    required this.isSelectAll,
    required this.onResetTransactions,
  }) : super(key: key);
  @override
  _CustomCardExampleState createState() => _CustomCardExampleState();
}

class _CustomCardExampleState extends State<CustomCardExample>
    with SingleTickerProviderStateMixin {
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
  }

  Future<void> _approvedTransaction(String docNo, String docType) async {
  try {
    var responseData = await ApiServiceAdmin().approveTransaction(docNo, docType);

    if (responseData['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction approved successfully')),
      );
      setState(() {
        _showDetails = false;
        _checkDetails.clear();
      });
      widget.onResetTransactions?.call();
    } else {
      throw Exception('Failed to approve transaction');
    }
  } catch (e) {
    print('Error approving transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error approving transaction: $e')),
    );
  }
}
  void resetTransaction(Transaction newTransaction) {
    setState(() {
      _showDetails = false;
      _checkDetails.clear();
    });
    _fetchCheckDetails(newTransaction.docNo, newTransaction.docType);
  }

Future<void> _fetchCheckDetails(String docNo, String docType) async {
  try {
    List<dynamic> data = await ApiServiceAdmin().fetchCheckDetails(docNo, docType);
    
    if (!mounted) return; // Check if the widget is still mounted

    data.sort((a, b) => DateTime.parse(b['date_trans'])
        .compareTo(DateTime.parse(a['date_trans'])));
    
    if (mounted) {
      setState(() {
        _checkDetails = List<Map<String, dynamic>>.from(data);
      });
    }
  } catch (e) {
    print('Error fetching check details: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching check details: $e')),
      );
    }
  }
}

Future<void> _returnTransaction(String docNo, String docType, String approverRemarks) async {
  try {
    var responseData = await ApiServiceAdmin().returnTransaction(docNo, docType, approverRemarks);

    if (responseData['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction returned successfully')),
      );
      resetTransaction(widget.transaction);
      widget.onResetTransactions?.call();
    } else {
      throw Exception('Failed to return transaction');
    }
  } catch (e) {
    print('Error returning transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error returning transaction: $e')),
    );
  }
}


  void _toggleSelection() {
    widget.onSelectChanged?.call(!widget.transaction.isSelected);
  }

  void _showRemarksDialog(BuildContext context, String docNo, String docType,
      String currentRemarks) {
    TextEditingController _remarksController =
        TextEditingController(text: currentRemarks);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remarks'),
          content: TextField(
            controller: _remarksController,
            decoration: InputDecoration(
              hintText: 'Enter your remarks here',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text('Send'),
              onPressed: () {
                // Handle send action here
                String remarks =
                    _remarksController.text.trim(); // Trim whitespace
                if (remarks.isNotEmpty) {
                  print('Remarks: $remarks');
                  _returnTransaction(docNo, docType, remarks).then((_) {
                    Navigator.of(context)
                        .pop(); // Close the dialog after successful transaction
                  }).catchError((error) {
                    print('Error updating remarks: $error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating remarks: $error'),
                      ),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Remarks cannot be empty'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _rejectTransaction(String docNo, String docType) async {
  try {
    var responseData = await ApiServiceAdmin().rejectTransaction(docNo, docType);

    if (responseData['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction rejected successfully')),
      );
      // Reset the card state
      setState(() {
        _showDetails = false;
        _checkDetails.clear();
      });
      widget.onResetTransactions?.call();
    } else {
      throw Exception('Failed to reject transaction');
    }
  } catch (e) {
    print('Error rejecting transaction: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error rejecting transaction: $e')),
    );
  }
}

  Widget _buildCheckDetailsTable(List<Map<String, dynamic>> checkDetailsList) {
    List<TableRow> rows = [];

    // Function to add a table row for debit or credit details
    void addTableRow(Map<String, dynamic> details, bool showDebit, int index) {
      // Determine if to show the peso sign based on the index
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

    // Collect debit and credit transactions separately
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

    // Add debit transactions first
    for (int i = 0; i < debits.length; i++) {
      addTableRow(debits[i], true, i);
    }

    // Add credit transactions next
    for (int i = 0; i < credits.length; i++) {
      addTableRow(credits[i], false, i);
    }

    // Return the table with rows
    return Column(
      children: [
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
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.transaction.onlineTransactionStatus == 'T')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAttachments(
                          docType: widget.transaction.docType,
                          docNo: widget.transaction.docNo,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.attachment_rounded),
                  label: Text('View Attachment'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(12),
                    backgroundColor: const Color.fromARGB(255, 187, 196, 204),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.005,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _approvedTransaction(
                    widget.transaction.docNo, widget.transaction.docType);
              },
              icon: Icon(Icons.check),
              label: Text('Approve'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(12),
                backgroundColor: const Color.fromARGB(255, 187, 196, 204),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(
              height: 2,
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showRemarksDialog(
                  context,
                  widget.transaction.docNo,
                  widget.transaction.docType,
                  widget.transaction.approverRemarks,
                );
              },
              icon: Icon(Icons.keyboard_return_outlined),
              label: Text('Return'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(12),
                backgroundColor: const Color.fromARGB(255, 187, 196, 204),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(
              height: 2,
            ),
            ElevatedButton.icon(
              onPressed: () {
                _rejectTransaction(
                    widget.transaction.docNo, widget.transaction.docType);
              },
              icon: Icon(Icons.cancel_rounded),
              label: Text('Reject'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(12),
                backgroundColor: const Color.fromARGB(255, 187, 196, 204),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Icon _buildCheckboxIcon() {
    if (widget.isSelected) {
      return Icon(
        Icons.check_box,
        color: Colors.white,
      );
    } else {
      return Icon(
        Icons.check_box_outline_blank,
        color: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: _showDetails ? null : screenHeight * 0.312,
      child: Card(
        shadowColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        color: Color.fromARGB(255, 79, 128, 189),
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
                        '${widget.transaction.docType}#${widget.transaction.docNo}; ${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.transDate))}',
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
                        '₱${NumberFormat('#,##0.00').format(double.parse(widget.transaction.checkAmount))}',
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
                        '${widget.transaction.checkNo}; ${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.checkDate))}\n${widget.transaction.checkBankDrawee}',
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
                      _showDetails ? 'Hide Details' : 'View Details',
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleSelection,
                    icon: _buildCheckboxIcon(),
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
