import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/transmitter_card_notification.dart';
import '/models/user_transaction.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '../../api_services/api_services.dart';
import 'reprocessing/rep_details.dart';
import 'uploading/user_menu.dart';

class UploaderNotification extends StatefulWidget {
  @override
  _UploaderNotificationState createState() =>
      _UploaderNotificationState();
}

class _UploaderNotificationState extends State<UploaderNotification> {
  int notificationCount = 0;
  int _reprocessingCount = 0;
  int _transmittalCount = 0;
  int _uploadingCount = 0;
  bool isLoading = true;
  final ApiService _apiService = ApiService();

  List<UserTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    fetchNewNotificationCount();
  }

  Future<Map<String, int>> fetchNewNotificationCount() async {
    try {
      final response = await http.get(
          Uri.parse('https://backend-approval.azurewebsites.net/notification_count.php'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'reprocessingCount': jsonResponse['reprocessing_count'] ?? 0,
          'transmittalCount': jsonResponse['transmittal_count'] ?? 0,
          'uploadingCount': jsonResponse['uploading_count'] ?? 0,
        };
      } else {
        throw Exception('Failed to load notification count');
      }
    } catch (e) {
      print('Error fetching notification count: $e');
      return {
        'reprocessingCount': 0,
        'transmittalCount': 0,
        'uploadingCount': 0,
      };
    }
  }

  void updateNotificationCount(
      int reprocessingCount, int transmittalCount, int uploadingCount) {
    setState(() {
      notificationCount = reprocessingCount + transmittalCount + uploadingCount;
      _reprocessingCount = reprocessingCount;
      _transmittalCount = transmittalCount;
      _uploadingCount = uploadingCount;
    });
  }

  void onNewTransactionReceived() async {
    final counts = await fetchNewNotificationCount();
    updateNotificationCount(
      counts['reprocessingCount']!,
      counts['transmittalCount']!,
      counts['uploadingCount']!,
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<UserTransaction> fetchedTransactions =
          await _apiService.loadTransactions();

      setState(() {
        setState(() {
          transactions = fetchedTransactions
              .where((transaction) =>
                (transaction.transactionStatus == 'R' &&
                    transaction.onlineProcessingStatus == 'U') ||
                (transaction.transactionStatus == 'R' &&
                    transaction.onlineProcessingStatus == 'R') ||
                (transaction.transactionStatus == 'R' &&
                    transaction.onlineProcessingStatus == 'ND') ||
                transaction.transactionStatus == 'N' ||
                transaction.transactionStatus == 'A')
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
    double screenHeight = screenSize.height;
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
                      '$notificationCount',
                      style: TextStyle(color: Colors.white),
                    ),
                    badgeStyle: BadgeStyle(
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Handle notifications button tap
                      },
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
                          builder: (context) => const UserMenuWindow()),
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
      body: Column(
        children: [
          Expanded(
            child: _buildTransactionList(),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Center(
        child: const Text(
          'No notification found!',
          style: TextStyle(fontSize: 16),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (BuildContext context, int index) {
          UserTransaction transaction = transactions[index];
          return GestureDetector(
            onTap: () {
              if (transaction.onlineProcessingStatus == 'A' ||
                  transaction.transactionStatus == 'N' ||
                  transaction.onlineProcessingStatus == 'T'||
                  transaction.onlineProcessingStatus == 'TND'||
                  transaction.onlineProcessingStatus == 'U' ||
                  transaction.onlineProcessingStatus == 'ND'
                  ) {
                // Do nothing
              } else if (transaction.onlineProcessingStatus == 'R') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepDetails(
                        transaction: transaction, selectedDetails: []),
                  ),
                );
              } 
            },
            child: NotificationCard(
              transaction: transaction,
            ),
          );
        },
      );
    }
  }
}

class NotificationCard extends StatefulWidget {
  final UserTransaction transaction;

  const NotificationCard({
    required this.transaction,
  });

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool showDetails = false;

  void _toggleDetails() {
    setState(() {
      showDetails = !showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Ref: ${widget.transaction.docType}#${widget.transaction.docNo}; '
              '${DateFormat('MM/dd/yy').format(DateTime.parse(widget.transaction.dateTrans))}',
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
                Text(
                  'Uploaded Date: ${widget.transaction.onlineProcessDate}',
                  style: TextStyle(
                    fontSize: screenHeight * 0.013,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4), // Adjust spacing between lines
                Text(
                  'Status: ${widget.transaction.onlineProcessingStatusWord}',
                  style: TextStyle(
                    fontSize: screenHeight * 0.013,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: _toggleDetails,
              child: Text(showDetails ? 'Hide Details' : 'View Details'),
            ),
          ),
          if (showDetails)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  TransmitterCardNotification(transaction: widget.transaction),
            ),
        ],
      ),
    );
  }
}
