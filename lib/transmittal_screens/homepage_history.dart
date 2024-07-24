import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/user_transaction.dart';
import '../widgets/transmitter_card_history.dart';
import '../../api_services/transmitter_api.dart';

class HomepageHistory extends StatefulWidget {
  String selectedFilter;
  DateTime? startDate;
  DateTime? endDate;
  bool isOldestFirst;

  HomepageHistory({
    Key? key,
    required this.selectedFilter,
    this.startDate,
    this.endDate,
    required this.isOldestFirst,
  }) : super(key: key);

  @override
  _HomepageHistoryState createState() => _HomepageHistoryState();
}

class _HomepageHistoryState extends State<HomepageHistory> {
  List<UserTransaction> transactions = [];
     final TransmitterAPI _apiService = TransmitterAPI();


  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }


  Future<void> _loadTransactions() async {
  try {
    setState(() {}); // Show loading indicator here

    List<UserTransaction> fetchedTransactions = await _apiService.fetchTransactionsHistory();

    setState(() {
      transactions = fetchedTransactions.where((transaction) =>
        (transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'R') ||
        (transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'TND') ||
        (transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'T') ||
        (transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'U') ||
        (transaction.transactionStatus == 'R' && transaction.onlineProcessingStatus == 'ND') ||
        transaction.transactionStatus == 'N' || transaction.transactionStatus == 'A'
      ).toList();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to fetch transaction details: $e'),
        duration: Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() {}); // Hide loading indicator here
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
            items: <String>['All', 'Approved', 'Rejected', 'Returned', 'On Process']
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
    List<UserTransaction> filteredTransactions = transactions;
    if (widget.selectedFilter != 'All') {
      filteredTransactions = filteredTransactions.where((transaction) {
        switch (widget.selectedFilter) {
          case 'Approved':
            return transaction.transactionStatus == 'A';
          case 'Rejected':
            return transaction.transactionStatus == 'N';
          case 'Returned':
            return transaction.transactionStatus == 'R';
          case 'On Process':
            return transaction.onlineProcessingStatus == 'U' || transaction.onlineProcessingStatus == 'ND';
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
          UserTransaction transaction = filteredTransactions[index];
          return TransmitterCardHistory(
            transaction: transaction,
          );
        },
      );
    }
  }
}
