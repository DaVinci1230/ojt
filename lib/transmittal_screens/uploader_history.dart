import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '/widgets/transmitter_card_history.dart';
import '/models/user_transaction.dart';
import '../../api_services/transmitter_api.dart';

class UploaderHistory extends StatefulWidget {
  const UploaderHistory({Key? key}) : super(key: key);

  @override
  _UploaderHistoryState createState() => _UploaderHistoryState();
}

class _UploaderHistoryState extends State<UploaderHistory> {
  List<UserTransaction> transactions = [];
  String selectedFilter = 'All';
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  final TransmitterAPI _apiService = TransmitterAPI();

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    _loadTransactions();
  }

Future<void> _loadTransactions() async {
  setState(() {
    // Show loading indicator here
    isLoading = true;
  });

  try {
    List<UserTransaction> fetchedTransactions = await TransmitterAPI().fetchTransactionsHistory();
    setState(() {
      transactions = fetchedTransactions
          .where((transaction) =>
              (transaction.transactionStatus == 'R' &&
                  transaction.onlineProcessingStatus == 'T') ||
              (transaction.transactionStatus == 'R' &&
                  transaction.onlineProcessingStatus == 'TND') ||
              transaction.transactionStatus == 'N' ||
              transaction.transactionStatus == 'A')
          .toList();
    });
  } catch (e) {
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to fetch transaction details: $e'),
        duration: Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() {
      // Hide loading indicator here
      isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Column(
        children: [
          _buildFilterButton(),
          _buildDateRangePicker(context),
          Expanded(
            child: _buildTransactionList(),
          )
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              DropdownButton<String>(
                value: selectedFilter,
                dropdownColor: Color.fromARGB(255, 235, 238, 240),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedFilter = newValue!;
                  });
                  _loadTransactions(); // Reload transactions after filter change
                },
                items: <String>['All', 'Approved', 'Rejected', 'Returned', 'On process']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(
                width: 15,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    final DateFormat formatter = DateFormat('MMMM d, y');
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('From'),
          ElevatedButton(
            onPressed: () {
              _selectStartDate(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              formatter.format(startDate!),
              style: TextStyle(
                // Style
                color: Colors.black,
              ),
            ),
          ),
          Text(
            'to',
            style: TextStyle(fontSize: 16),
          ),
          ElevatedButton(
            onPressed: () {
              _selectEndDate(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              formatter.format(endDate!),
              style: TextStyle(
                // Style
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    List<UserTransaction> filteredTransactions = transactions;
    if (selectedFilter != 'All') {
      filteredTransactions = filteredTransactions.where((transaction) {
        switch (selectedFilter) {
          case 'Approved':
            return transaction.transactionStatus == 'A';
          case 'Rejected':
            return transaction.transactionStatus == 'N';
          case 'Returned':
            return transaction.transactionStatus == 'R' && transaction.onlineTransactionStatus == 'R';
          case 'On Process':
          return transaction.onlineProcessingStatus == 'T' || transaction.onlineProcessingStatus == 'TND';
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
        child: const Text(
          'No transactions found!',
          style: TextStyle(fontSize: 16),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (BuildContext context, int index) {
          UserTransaction transaction = filteredTransactions[index];
          return TransmitterCardHistory(
            transaction: transaction,
          );
        },
      );
    }
  }
}
