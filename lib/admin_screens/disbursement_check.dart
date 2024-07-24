import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/admin_screens/approver_notification.dart';
import '../models/admin_transaction.dart';
import '../widgets/card.dart';
import 'admin_homepage.dart';
import 'admin_menu_window.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import '../api_services/api_services_admin.dart';

class DisbursementCheque extends StatefulWidget {
  const DisbursementCheque({Key? key}) : super(key: key);

  @override
  _DisbursementChequeState createState() => _DisbursementChequeState();
}

mixin SelectionMixin<T extends StatefulWidget> on State<T> {
  int notificationCount = 0;
  bool _selectAllTabT = false;
  bool _selectAllTabTnd = false;

  void toggleSelectAllTabT(bool newValue) {
    setState(() {
      _selectAllTabT = newValue;
    });
  }

  void toggleSelectAllTabTnd(bool newValue) {
    setState(() {
      _selectAllTabTnd = newValue;
    });
  }
}

class _DisbursementChequeState extends State<DisbursementCheque>
    with SingleTickerProviderStateMixin, SelectionMixin<DisbursementCheque> {
  int pendingCountT = 0;
  int pendingCountTnd = 0;
  late TabController _tabController;
  late Future<List<Transaction>> _transactionsFutureT;
  late Future<List<Transaction>> _transactionsFutureTnd;
  List<Transaction> selectedTransactions = [];
  double _totalSelectedAmount = 0.0;
  final ApiServiceAdmin _apiServiceAdmin = ApiServiceAdmin();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactionsFutureT = _fetchTransactionDetailsDisbursement('T');
    _transactionsFutureTnd = _fetchTransactionDetailsDisbursement('TND');
    _countNotif();
  }

  String getCurrentDate() {
    final DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<List<Transaction>> _fetchTransactionDetailsDisbursement(
      String onlineTransactionStatus) async {
    try {
      List<Transaction> fetchedTransactions = await _apiServiceAdmin
          .fetchTransactionDetailsDisbusrsement(onlineTransactionStatus);

      setState(() {
        if (onlineTransactionStatus == 'T') {
          pendingCountT = fetchedTransactions
              .where(
                  (transaction) => transaction.onlineTransactionStatus == 'T')
              .length;
        } else if (onlineTransactionStatus == 'TND') {
          pendingCountTnd = fetchedTransactions
              .where(
                  (transaction) => transaction.onlineTransactionStatus == 'TND')
              .length;
        }
      });

      return fetchedTransactions;
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
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

  Future<void> _returnTransaction(
      List<Transaction> transactions, String approverRemarks) async {
    try {
      await _apiServiceAdmin.returnTransactions(transactions, approverRemarks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions returned successfully')),
      );
    } catch (e) {
      print('Error returning transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error returning transactions: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomePage()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminMenuWindow()),
        );
        break;
    }
  }

  void _updateSelectedAmount(double selectedAmount) {
    setState(() {
      _totalSelectedAmount = selectedAmount;
    });
  }

  void _toggleSelectAllTabT() {
    bool newValue = !_selectAllTabT;
    setState(() {
      _selectAllTabT = newValue;
    });

    _transactionsFutureT.then((transactions) {
      for (var transaction in transactions) {
        if (transaction.onlineTransactionStatus == 'T') {
          transaction.isSelected = newValue;
          if (newValue && !selectedTransactions.contains(transaction)) {
            selectedTransactions.add(transaction);
          } else if (!newValue && selectedTransactions.contains(transaction)) {
            selectedTransactions.remove(transaction);
          }
        }
      }
      _calculateSelectedAmount(_transactionsFutureT);
    });
  }

  void _toggleSelectAllTabTnd() {
    bool newValue = !_selectAllTabTnd;
    setState(() {
      _selectAllTabTnd = newValue;
    });

    _transactionsFutureTnd.then((transactions) {
      for (var transaction in transactions) {
        if (transaction.onlineTransactionStatus == 'TND') {
          transaction.isSelected = newValue;
          if (newValue && !selectedTransactions.contains(transaction)) {
            selectedTransactions.add(transaction);
          } else if (!newValue && selectedTransactions.contains(transaction)) {
            selectedTransactions.remove(transaction);
          }
        }
      }
      _calculateSelectedAmount(_transactionsFutureTnd);
    });
  }

  void _toggleSelectTransaction(Transaction transaction, bool isSelected) {
    setState(() {
      transaction.isSelected = isSelected;

      if (isSelected) {
        if (!selectedTransactions.contains(transaction)) {
          selectedTransactions.add(transaction);
        }
      } else {
        selectedTransactions.remove(transaction);
      }

      // Update total selected amount
      _calculateSelectedAmount(transaction.onlineTransactionStatus == 'T'
          ? _transactionsFutureT
          : _transactionsFutureTnd);

      if (transaction.onlineTransactionStatus == 'T') {
        if (!isSelected) {
          _selectAllTabT = false;
        } else {
          bool allSelectedT = true;
          _transactionsFutureT.then((transactions) {
            for (var transaction in transactions) {
              if (!transaction.isSelected &&
                  transaction.onlineTransactionStatus == 'T') {
                allSelectedT = false;
                break;
              }
            }
            setState(() {
              _selectAllTabT = allSelectedT;
            });
          });
        }
      } else if (transaction.onlineTransactionStatus == 'TND') {
        if (!isSelected) {
          _selectAllTabTnd = false;
        } else {
          bool allSelectedTnd = true;
          _transactionsFutureTnd.then((transactions) {
            for (var transaction in transactions) {
              if (!transaction.isSelected &&
                  transaction.onlineTransactionStatus == 'TND') {
                allSelectedTnd = false;
                break;
              }
            }
            setState(() {
              _selectAllTabTnd = allSelectedTnd;
            });
          });
        }
      }
    });
  }

  void _updateSelectedTransactions(
    Future<List<Transaction>> transactionsFuture,
    bool selectAll,
    bool isTabT,
  ) {
    setState(() {
      transactionsFuture.then((transactions) {
        return transactions.map((transaction) {
          if ((isTabT && transaction.onlineTransactionStatus == 'T') ||
              (!isTabT && transaction.onlineTransactionStatus == 'TND')) {
            transaction.isSelected = selectAll;
          }
          return transaction;
        }).toList();
      }).then((updatedTransactions) {
        setState(() {
          if (isTabT) {
            _transactionsFutureT = Future.value(updatedTransactions);
          } else {
            _transactionsFutureTnd = Future.value(updatedTransactions);
          }
        });

        // Calculate selected amount for the current tab only
        if (isTabT) {
          _calculateSelectedAmount(_transactionsFutureT);
        } else {
          _calculateSelectedAmount(_transactionsFutureTnd);
        }
      });
    });
  }

  void _calculateSelectedAmount(
    Future<List<Transaction>> transactionsFuture,
  ) {
    transactionsFuture.then((transactions) {
      double totalAmount = 0.0;
      for (var transaction in transactions) {
        if (transaction.isSelected) {
          totalAmount += double.tryParse(transaction.checkAmount) ?? 0.0;
        }
      }
      setState(() {
        _totalSelectedAmount = totalAmount;
      });
    }).catchError((e) {
      print('Failed to calculate total amount: $e');
    });
  }

  void _rejectTransactionsDisbursement(List<Transaction> transactions) async {
    try {
      await _apiServiceAdmin.rejectTransactions(transactions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions rejected successfully')),
      );

      setState(() {
        _transactionsFutureT = _fetchTransactionDetailsDisbursement('T');
        _transactionsFutureTnd = _fetchTransactionDetailsDisbursement('TND');
        _selectAllTabT = false;
        _selectAllTabTnd = false;
      });
    } catch (e) {
      print('Error rejecting transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting transactions: $e')),
      );
    }
  }

  void _approvedTransaction(List<Transaction> transactions) async {
    try {
      await _apiServiceAdmin.approveTransactions(transactions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions approved successfully')),
      );

      setState(() {
        _transactionsFutureT = _fetchTransactionDetailsDisbursement('T');
        _transactionsFutureTnd = _fetchTransactionDetailsDisbursement('TND');
        _selectAllTabT = false;
        _selectAllTabTnd = false;
      });
    } catch (e) {
      print('Error approving transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving transactions: $e')),
      );
    }
  }

  void _approvedAllTransaction() {
    _transactionsFutureT.then((transactions) {
      List<Transaction> selectedTransactions =
          transactions.where((transaction) => transaction.isSelected).toList();

      if (selectedTransactions.isNotEmpty) {
        _approvedTransaction(selectedTransactions);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No transactions selected to approve')),
        );
      }
      setState(() {
        _selectAllTabT = false;
      });
    }).catchError((error) {
      print('Failed to fetch transactions: $error');
    });
  }

  void _returnAllTransactionDisbursement(List<Transaction> transactions) async {
    try {
      await _apiServiceAdmin.rejectTransactions(transactions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions rejected successfully')),
      );
      setState(() {
        _transactionsFutureT = _fetchTransactionDetailsDisbursement('T');
        _transactionsFutureTnd = _fetchTransactionDetailsDisbursement('TND');
        _selectAllTabT = false;
        _selectAllTabTnd = false;
      });
    } catch (e) {
      print('Error rejecting transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting transactions: $e')),
      );
    }
  }

  void _returnAllTransactions() {
    _transactionsFutureT.then((transactions) {
      List<Transaction> selectedTransactions =
          transactions.where((transaction) => transaction.isSelected).toList();

      if (selectedTransactions.isNotEmpty) {
        _returnAllTransactionDisbursement(selectedTransactions);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No transactions selected to reject')),
        );
      }
      setState(() {
        _selectAllTabT = false;
      });
    }).catchError((error) {
      print('Failed to fetch transactions: $error');
    });
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

                    // Refresh the transactions after returning
                    setState(() {
                      _transactionsFutureT =
                          _fetchTransactionDetailsDisbursement('T');
                      _transactionsFutureTnd =
                          _fetchTransactionDetailsDisbursement('TND');
                    });
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

  void _rejectAllTransactions() {
    _transactionsFutureT.then((transactions) {
      List<Transaction> selectedTransactions =
          transactions.where((transaction) => transaction.isSelected).toList();

      if (selectedTransactions.isNotEmpty) {
        _rejectTransactionsDisbursement(selectedTransactions);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No transactions selected to reject')),
        );
      }
      setState(() {
        _selectAllTabT = false;
      });
    }).catchError((error) {
      print('Failed to fetch transactions: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    Size screenSize = MediaQuery.of(context).size;

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
                  'Tasks',
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
                    Navigator.push(
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pendingCountT',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Pending with Attachments',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontFamily: 'tahoma',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pendingCountTnd',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Pending with no Attachments',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontFamily: 'tahoma',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(_transactionsFutureT = _transactionsFutureTnd, 'T',
                _selectAllTabT, _toggleSelectAllTabT),
            _buildTabContent(
              _transactionsFutureTnd = _transactionsFutureT,
              'TND',
              _selectAllTabTnd,
              _toggleSelectAllTabTnd,
            ),
          ],
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
        currentIndex: 1,
        selectedItemColor: const Color.fromARGB(255, 0, 110, 255),
        onTap: _onItemTapped,
      ),
      floatingActionButton: Visibility(
        visible: _totalSelectedAmount > 0,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: screenSize.width * 0.65,
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
              SizedBox(width: screenSize.width * 0.02),
              ElevatedButton.icon(
                onPressed: () {
                  _approvedAllTransaction();
                  setState(() {
                    _totalSelectedAmount = 0.0;
                  });
                },
                icon: Icon(
                  Icons.check,
                  size: screenSize.width * 0.05,
                  color: Colors.white,
                ),
                label: Text(
                  'Approve',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.03,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.02,
                    vertical: screenSize.width * 0.015,
                  ),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.04),
                    side: BorderSide(
                      color: Colors.blue,
                      width: screenSize.width * 0.01,
                    ),
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
                  _rejectAllTransactions();
                  setState(() {
                    _totalSelectedAmount = 0.0;
                  });
                },
                icon: Icon(
                  Icons.cancel_rounded,
                  size: screenSize.width * 0.03,
                  color: Colors.white,
                ),
                label: Text(
                  'Reject',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.03,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.02,
                    vertical: screenSize.width * 0.015,
                  ),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.04),
                    side: BorderSide(
                      color: Colors.blue,
                      width: screenSize.width * 0.01,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    Future<List<Transaction>> future,
    String status,
    bool selectAll,
    VoidCallback toggleSelectAll,
  ) {
    Widget buildSelectAllButton() {
      return IconButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _toggleSelectAllTabT();
          } else if (_tabController.index == 1) {
            _toggleSelectAllTabTnd();
          }
        },
        icon: Icon(
          selectAll ? Icons.check_box : Icons.check_box_outline_blank,
          size: 30,
        ),
      );
    }

    return FutureBuilder<List<Transaction>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No transactions found!',
              style: TextStyle(fontSize: 12),
            ),
          );
        } else {
          final List<Transaction> transactions = snapshot.data!;
          List<Transaction> filteredTransactions = transactions
              .where((transaction) =>
                  transaction.onlineTransactionStatus == status)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filteredTransactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: ₱${NumberFormat('#,###.##').format(_totalSelectedAmount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      buildSelectAllButton(),
                      SizedBox(width: 8),
                      Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return CustomCardExample(
                      onResetTransactions: () {
                        setState(() {
                          _transactionsFutureT =
                              _fetchTransactionDetailsDisbursement('T');
                          _transactionsFutureTnd =
                              _fetchTransactionDetailsDisbursement('TND');
                        });
                      },
                      transaction: filteredTransactions[index],
                      isSelected:
                          filteredTransactions[index].isSelected ?? false,
                      onSelectChanged: (newValue) {
                        _toggleSelectTransaction(
                            filteredTransactions[index], newValue);
                      },
                      showSelectAllButton: false, // Adjust based on your needs
                      isSelectAll: selectAll, // Pass the selectAll flag
                      onSelectedAmountChanged: (transactionsFuture) {
                        _updateSelectedAmount(_totalSelectedAmount);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
