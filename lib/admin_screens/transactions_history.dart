import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/admin_transaction.dart';
import '../widgets/history_card.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> transactions = [];
  String selectedFilter = 'All';
  DateTime? startDate;
  DateTime? endDate;
  bool isOldestFirst = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    _loadTransactions();
    isOldestFirst = false;
  }

  Future<void> _loadTransactions() async {
    try {
      // Show loading indicator here
      setState(() {});

      var url = Uri.parse(
          'http://192.168.131.94/localconnect/transaction_history.php');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> fetchedTransactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
              .toList();
          fetchedTransactions.sort((a, b) => isOldestFirst
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
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load transaction details: ${response.statusCode}');
      }
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
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
      _loadTransactions();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
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
          )
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
                isOldestFirst = !isOldestFirst;
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
              isOldestFirst ? 'Oldest First' : 'Newest First',
              style: TextStyle(
                fontSize: screenSize.width * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          DropdownButton<String>(
            value: selectedFilter,
            dropdownColor: Color.fromARGB(255, 235, 238, 240),
            onChanged: (String? newValue) {
              setState(() {
                selectedFilter = newValue!;
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
              formatter.format(startDate!),
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
              formatter.format(endDate!),
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
    if (selectedFilter != 'All') {
      filteredTransactions = filteredTransactions.where((transaction) {
        switch (selectedFilter) {
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
    if (startDate != null && endDate != null) {
      filteredTransactions = filteredTransactions.where((transaction) {
        try {
          var transactionDate = DateTime.parse(transaction.onlineProcessDate);
          return transactionDate
                  .isAfter(startDate!.subtract(Duration(days: 1))) &&
              transactionDate.isBefore(endDate!.add(Duration(days: 1)));
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
