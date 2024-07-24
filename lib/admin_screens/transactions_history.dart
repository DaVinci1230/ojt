import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_services/api_services_admin.dart';
import '../models/admin_transaction.dart';
import '../widgets/history_card.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  String selectedFilter;
  DateTime? startDate;
  DateTime? endDate;
  bool isOldestFirst;

  TransactionsScreen({
    Key? key,
    required this.selectedFilter,
    this.startDate,
    this.endDate,
    required this.isOldestFirst,
  }) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> transactions = [];
    final ApiServiceAdmin _apiServiceAdmin = ApiServiceAdmin();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

Future<void> _loadTransactions() async {
  try {
    setState(() {});

    List<Transaction> fetchedTransactions = await _apiServiceAdmin.loadTransactions();

    fetchedTransactions.sort((a, b) => widget.isOldestFirst
        ? a.onlineProcessDate.compareTo(b.onlineProcessDate)
        : b.onlineProcessDate.compareTo(a.onlineProcessDate));

    setState(() {
      transactions = fetchedTransactions
          .where((transaction) =>
              (transaction.transactionStatus == 'R' &&
                  transaction.onlineTransactionStatus == 'R') ||
              transaction.transactionStatus == 'A' ||
              transaction.transactionStatus == 'N')
          .toList();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to fetch transaction details: $e'),
        duration: Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() {});
  }
}


  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        widget.startDate = picked;
      });
      _loadTransactions();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        widget.endDate = picked;
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Column(
        children: [
          _buildFilterButton(screenSize),
          _buildDateRangePicker(context, screenSize),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(Size screenSize) {
    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.isOldestFirst = !widget.isOldestFirst;
              });
              _loadTransactions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.02,
              ),
            ),
            child: Text(
              widget.isOldestFirst ? 'Oldest First' : 'Newest First',
              style: TextStyle(
                fontSize: screenSize.width * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          DropdownButton<String>(
            value: widget.selectedFilter,
            dropdownColor: Color.fromARGB(255, 235, 238, 240),
            onChanged: (String? newValue) {
              setState(() {
                widget.selectedFilter = newValue!;
              });
              _loadTransactions();
            },
            items: <String>['All', 'Approved', 'Rejected', 'Returned']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: screenSize.width * 0.03),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context, Size screenSize) {
    final DateFormat formatter = DateFormat('MMMM d, y');
    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'From',
            style: TextStyle(fontSize: screenSize.width * 0.03),
          ),
          ElevatedButton(
            onPressed: () {
              _selectStartDate(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.02,
              ),
            ),
            child: Text(
              formatter.format(widget.startDate!),
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.03,
              ),
            ),
          ),
          Text(
            'to',
            style: TextStyle(fontSize: screenSize.width * 0.03),
          ),
          ElevatedButton(
            onPressed: () {
              _selectEndDate(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.02,
              ),
            ),
            child: Text(
              formatter.format(widget.endDate!),
              style: TextStyle(
                color: Colors.black,
                fontSize: screenSize.width * 0.03,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final screenSize = MediaQuery.of(context).size;
    List<Transaction> filteredTransactions = transactions;
    if (widget.selectedFilter != 'All') {
      filteredTransactions = filteredTransactions.where((transaction) {
        switch (widget.selectedFilter) {
          case 'Approved':
            return transaction.transactionStatus == 'A';
          case 'Rejected':
            return transaction.transactionStatus == 'N';
          case 'Returned':
            return transaction.transactionStatus == 'R';
          default:
            return true;
        }
      }).toList();
    }
    if (widget.startDate != null && widget.endDate != null) {
      filteredTransactions = filteredTransactions.where((transaction) {
        try {
          var transactionDate = DateTime.parse(transaction.onlineProcessDate);
          return transactionDate
                  .isAfter(widget.startDate!.subtract(Duration(days: 1))) &&
              transactionDate.isBefore(widget.endDate!.add(Duration(days: 1)));
        } catch (e) {
          print('Error parsing date "${transaction.onlineProcessDate}": $e');
          return false;
        }
      }).toList();
    }

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions found!',
          style: TextStyle(fontSize: screenSize.width * 0.04),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (BuildContext context, int index) {
          Transaction transaction = filteredTransactions[index];
          return TransactionsCard(
            transaction: transaction,
          );
        },
      );
    }
  }
}
