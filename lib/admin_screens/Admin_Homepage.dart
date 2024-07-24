import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/admin_screens/approver_notification.dart';
import 'disbursement_check.dart';
import 'admin_menu_window.dart';
import '/widgets/card.dart';
import '/models/admin_transaction.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '/api_services/api_services_admin.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int notificationCount = 0;
  int _selectedIndex = 0;
  int pendingCount = 0;
  late Future<List<Transaction>> _transactionsFuture;
  List<Transaction> selectedTransactions = [];
  double totalSelectedAmount = 0.0;
  bool allSelected = false;
  final ApiServiceAdmin _apiServiceAdmin = ApiServiceAdmin();

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactionDetails();
    _countNotif();
  }

  Future<List<Transaction>> _fetchTransactionDetails() async {
    try {
      List<Transaction> transactions =
          await _apiServiceAdmin.fetchTransactionDetails();

      setState(() {
        pendingCount = transactions
            .where((transaction) =>
                transaction.onlineTransactionStatus == 'TND' ||
                transaction.onlineTransactionStatus == 'T')
            .length;
      });

      return transactions;
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  Future<void> _countNotif() async {
    try {
      List<Transaction> transactions = await _apiServiceAdmin.fetchTransactionDetails();
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

  void _refreshTransactionList() {
    setState(() {
      _transactionsFuture = _fetchTransactionDetails();
      selectedTransactions.clear();
      totalSelectedAmount = 0.0;
    });
  }

  void _resetTransactions() {
    setState(() {
      selectedTransactions.clear();
      totalSelectedAmount = 0.0;
    });
  }

  void _toggleTransactionSelection(Transaction transaction) {
    setState(() {
      if (selectedTransactions.contains(transaction)) {
        selectedTransactions.remove(transaction);
      } else {
        selectedTransactions.add(transaction);
      }
      _calculateTotalSelectedAmount(selectedTransactions);
    });
  }

  Future<void> _approvedTransaction(List<Transaction> transactions) async {
    try {
      await _apiServiceAdmin.approveTransactions(transactions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions approved successfully')),
      );
      _refreshTransactionList();
    } catch (e) {
      print('Error approving transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving transactions: $e')),
      );
    }
  }

  Future<void> _returnTransaction(
      List<Transaction> transactions, String approverRemarks) async {
    try {
      await _apiServiceAdmin.returnTransactions(transactions, approverRemarks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions returned successfully')),
      );
      _refreshTransactionList();
    } catch (e) {
      print('Error returning transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error returning transactions: $e')),
      );
    }
  }

  void _showDialog(
      BuildContext context, List<Transaction> selectedTransactions) {
    TextEditingController _remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remarks for Selected Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selected Transactions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...selectedTransactions
                  .map((transaction) =>
                      Text('${transaction.docNo} - ${transaction.docType}'))
                  .toList(),
              SizedBox(height: 10),
              TextField(
                controller: _remarksController,
                decoration: InputDecoration(
                  hintText: 'Enter your remarks here',
                ),
              ),
            ],
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
                String remarks = _remarksController.text.trim();
                if (remarks.isNotEmpty) {
                  print('Remarks: $remarks');
                  _returnTransaction(selectedTransactions, remarks).then((_) {
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

  Future<void> _rejectTransaction(List<Transaction> transactions) async {
    try {
      await _apiServiceAdmin.rejectTransactions(transactions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions rejected successfully')),
      );
      _refreshTransactionList();
    } catch (e) {
      print('Error rejecting transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting transactions: $e')),
      );
    }
  }

  void _calculateTotalSelectedAmount(List<Transaction> transactions) {
    double totalAmount = 0.0;
    transactions.forEach((transaction) {
      totalAmount += double.parse(transaction.checkAmount);
    });
    setState(() {
      totalSelectedAmount = totalAmount;
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Home (AdminHomePage)
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DisbursementCheque()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMenuWindow()),
        );
        break;
    }
  }

  String _plusS(int pendingCount) {
    if (pendingCount > 1) {
      return 'Items';
    } else if (pendingCount == 1) {
      return 'Item';
    } else {
      return 'item'; // Handle other cases if needed
    }
  }

  Widget buildSelectAllButton(List<Transaction> transactions) {
    bool allSelected = selectedTransactions.length == transactions.length &&
        transactions.isNotEmpty;

    return IconButton(
      onPressed: () {
        setState(() {
          if (!allSelected) {
            selectedTransactions.clear();
            selectedTransactions.addAll(transactions);
          } else {
            selectedTransactions.clear();
          }
          _calculateTotalSelectedAmount(selectedTransactions);
        });
      },
      icon: Icon(
        allSelected ? Icons.check_box : Icons.check_box_outline_blank,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ApproverNotification()),
                            );
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
                              builder: (context) => AdminMenuWindow()),
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
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: screenHeight * 0.03,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DisbursementCheque()),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21.0),
                child: Container(
                  color: const Color.fromARGB(255, 79, 129, 189),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  height: 208,
                  width: screenSize.width * 0.9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disbursements \nfor approval',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Row(
                              children: [
                                Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    fontSize: 66,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  _plusS(pendingCount),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10, bottom: 85),
                        child: const Icon(
                          Icons.content_paste,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: FutureBuilder<List<Transaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text(
                      'No transactions found as of today.',
                      style: TextStyle(fontSize: 12),
                    ));
                  } else {
                    final List<Transaction> transactions = snapshot.data!;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: screenSize.width * 0.01,
                            ),
                            Expanded(
                              child: Text(
                                'Total: ₱ ${NumberFormat('#,###.##').format(totalSelectedAmount)}',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.035,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            buildSelectAllButton(transactions),
                            Text(
                              'Select All',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.03,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(
                              width: screenSize.width * .01,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: transactions.map((transaction) {
                                return CustomCardExample(
                                  transaction: transaction,
                                  isSelectAll: false,
                                  showSelectAllButton: true,
                                  onSelectChanged: (bool isSelected) {
                                    _toggleTransactionSelection(transaction);
                                  },
                                  onSelectedAmountChanged:
                                      (double selectedAmount) {
                                    print(
                                        'Selected amount changed: $selectedAmount');
                                  },
                                  isSelected: selectedTransactions
                                      .contains(transaction),
                                  onResetTransactions: () {
                                    setState(() {
                                      _transactionsFuture =
                                          _fetchTransactionDetails();
                                      selectedTransactions.clear();
                                      totalSelectedAmount = 0.0;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.0025),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: totalSelectedAmount > 0,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: screenSize.width * 0.61,
          margin: EdgeInsets.only(
            bottom: screenSize.height * 0.02,
            right: screenSize.width * 0.005,
          ),
          padding: EdgeInsets.all(screenSize.width * 0.02),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 0, 0, 0),
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenSize.width * 0.05),
              topRight: Radius.circular(screenSize.width * 0.00),
              bottomLeft: Radius.circular(screenSize.width * 0.05),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: screenSize.width * 0.01),
              ElevatedButton.icon(
                onPressed: () {
                  _approvedTransaction(selectedTransactions);
                },
                icon: Icon(Icons.check,
                    size: screenSize.width * 0.025, color: Colors.white),
                label: Text(
                  'Approve',
                  style: TextStyle(
                      fontSize: screenSize.width * 0.025, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.02,
                      vertical: screenSize.width * 0.015),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.04),
                    side: BorderSide(
                        color: Colors.blue, width: screenSize.width * 0.01),
                  ),
                ),
              ),
              SizedBox(width: screenSize.width * 0.01),
              ElevatedButton.icon(
                onPressed: () {
                  _showDialog(context, selectedTransactions);
                },
                icon: Icon(Icons.keyboard_return_outlined,
                    size: screenSize.width * 0.025, color: Colors.white),
                label: Text(
                  'Return',
                  style: TextStyle(
                      fontSize: screenSize.width * 0.025, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.015,
                      vertical: screenSize.width * 0.015),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.04),
                    side: BorderSide(
                        color: Colors.blue, width: screenSize.width * 0.01),
                  ),
                ),
              ),
              SizedBox(width: screenSize.width * 0.01),
              ElevatedButton.icon(
                onPressed: () {
                  _rejectTransaction(selectedTransactions);
                },
                icon: Icon(Icons.cancel_rounded,
                    size: screenSize.width * 0.025, color: Colors.white),
                label: Text(
                  'Reject',
                  style: TextStyle(
                      fontSize: screenSize.width * 0.025, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.015,
                      vertical: screenSize.width * 0.015),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.04),
                    side: BorderSide(
                        color: Colors.blue, width: screenSize.width * 0.01),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_sharp),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 110, 255),
        onTap: _onItemTapped,
      ),
    );
  }
}
