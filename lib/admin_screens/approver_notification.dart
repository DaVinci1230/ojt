import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '/admin_screens/admin_menu_window.dart';
import '/transmittal_screens/homepage_menu.dart';
import '../widgets/approver_notification_card.dart';
import '../widgets/card.dart';
import '/models/admin_transaction.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '../api_services/api_services_admin.dart';

class ApproverNotification extends StatefulWidget {
  @override
  _ApproverNotificationState createState() => _ApproverNotificationState();
}

class _ApproverNotificationState extends State<ApproverNotification> {
  int notificationCount = 0;
  bool isLoading = true;
  final ApiServiceAdmin _apiServiceAdmin = ApiServiceAdmin();

  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _countNotif();
  }

  Future<void> _countNotif() async {
    try {
      List<Transaction> transactions =
          await _apiServiceAdmin.fetchTransactionDetails();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
                transaction.onlineTransactionStatus == 'TND' ||
                transaction.onlineTransactionStatus == 'T' &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Transaction> fetchedTransactions =
          await _apiServiceAdmin.loadTransactions();

      setState(() {
        setState(() {
          transactions = fetchedTransactions
              .where((transaction) =>
                  transaction.onlineTransactionStatus == 'TND' ||
                  transaction.onlineTransactionStatus == 'T' &&
                      transaction.notification == 'N')
              .toList();
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch transaction details: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 79, 128, 189),
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
                  'Notifications',
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
                      notificationCount > 0 ? '$notificationCount' : '',
                      style: TextStyle(color: Colors.white),
                    ),
                    badgeStyle: BadgeStyle(
                      badgeColor: notificationCount > 0
                          ? Colors.red
                          : Colors.transparent,
                      padding: EdgeInsets.all(6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
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
                          builder: (context) => const AdminMenuWindow()),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildTransactionList(),
    );
  }

  Widget _buildTransactionList() {
    List<Transaction> filteredTransactions = transactions;
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
          return NotificationCard(
            transaction: transaction,
          );
        },
      );
    }
  }
}

class NotificationCard extends StatefulWidget {
  final Transaction transaction;

  const NotificationCard({
    required this.transaction,
  });

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool showDetails = false;
  final ApiServiceAdmin _apiService = ApiServiceAdmin();

  Future<void> _removeNotification() async {
    try {
      await _apiService.removeNotification(
        widget.transaction.docNo,
        widget.transaction.docType,
      );
    } catch (e) {
      print('Error removing notification: $e');
      // Optionally show an error message or handle as needed
    }
  }

  void _toggleDetails() {
    setState(() {
      showDetails = !showDetails;
    });

    if (showDetails) {
      _removeNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Card(
      color: Color.fromARGB(255, 62, 194, 255),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${widget.transaction.docType}#${widget.transaction.docNo}; ${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.transDate))}',
              style: TextStyle(
                fontSize: screenHeight * 0.014,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Uploaded Date: ${widget.transaction.onlineProcessDate}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                _toggleDetails();
              },
              child: Text(showDetails ? 'Hide Details' : 'View Details'),
            ),
          ),
          if (showDetails)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ApproverNotificationCard(
                onResetTransactions: () {
                  setState(() {});
                },
                transaction: widget.transaction,
                isSelectAll: false,
                showSelectAllButton: true,
                onSelectChanged: (bool isSelected) {
                  // Handle select change
                },
                onSelectedAmountChanged: (double selectedAmount) {
                  print('Selected amount changed: $selectedAmount');
                },
                isSelected: false,
              ),
            ),
        ],
      ),
    );
  }
}
