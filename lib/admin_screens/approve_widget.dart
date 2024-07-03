import 'package:flutter/material.dart';
import '../models/admin_transaction.dart';

import '../widgets/card.dart';
import 'disbursement_check.dart';
import 'admin_homepage.dart'; 

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}
class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Center(
        child: const Text(
          'No transaction found!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
