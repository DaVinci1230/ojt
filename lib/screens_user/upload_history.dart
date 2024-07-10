import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ojt/widgets/uploader_card_history.dart';
import '/models/user_transaction.dart';

class MarkHistory extends StatefulWidget {
  const MarkHistory({Key? key}) : super(key: key);

  @override
  _MarkHistoryState createState() => _MarkHistoryState();
}

class _MarkHistoryState extends State<MarkHistory> {
  List<Transaction> transactions = [];
  String selectedFilter = 'All';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      // Show loading indicator here
      setState(() {});

      var url =
          Uri.parse('http://127.0.0.1/localconnect/transmitter_history.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> fetchedTransactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
              .toList();
          fetchedTransactions.sort(
              (a, b) => b.onlineProcessDate.compareTo(a.onlineProcessDate));
          setState(() {
            transactions = fetchedTransactions
                .where((transaction) =>
                    (transaction.transactionStatus == 'R' &&
                        transaction.onlineProcessingStatus == 'T') ||
                    (transaction.transactionStatus == 'R' &&
                    transaction.onlineProcessingStatus == 'TND') ||
                    transaction.transactionStatus == 'N' 
                    || transaction.transactionStatus == 'A'
                    ) 
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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch transaction details: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      // Hide loading indicator here
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
    List<Transaction> filteredTransactions = transactions;
    if (selectedFilter != 'All') {
      filteredTransactions = filteredTransactions.where((transaction) {
        switch (selectedFilter) {
          case 'Approved':
            return transaction.transactionStatus == 'A';
          case 'Rejected':
            return transaction.transactionStatus == 'N';
          case 'Returned':
            return transaction.transactionStatus == 'R' && transaction.onlineTransactionStatus == 'R';
          case 'On process':
          return transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'TND';
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
          Transaction transaction = filteredTransactions[index];
          return MarkCardHistory(
            transaction: transaction,
          );
        },
      );
    }
  }
}
