import 'package:flutter/material.dart';
import 'package:scrollable_table_view/scrollable_table_view.dart';
import '../models/user_transaction.dart'; // Import your Transaction model
import 'package:intl/intl.dart';

class ScrollableTableViewWidget extends StatelessWidget {
  final List<String> headers;
  final List<Transaction> transactions;
  final Function(Transaction) onRowTap;

  const ScrollableTableViewWidget({
    Key? key,
    required this.headers,
    required this.transactions,
    required this.onRowTap,
    required List rows,
  }) : super(key: key);

  String createDocRef(String docType, String docNo, DateTime transDate) {
    final DateFormat formatter = DateFormat('MM/dd/yy');
    final String formattedDate = formatter.format(transDate);
    return 'Ref: $docType#$docNo; $formattedDate';
  }

  String formatAmount(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_PH', // Filipino locale
      symbol: '₱', // Currency symbol for Philippine Peso
      decimalDigits: 2, // Number of decimal places
    );
    return currencyFormat.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate column widths based on available screen width
        final double columnWidth = constraints.maxWidth / headers.length;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 12,
              child: ScrollableTableView(
                headerBackgroundColor: Color.fromARGB(108, 79, 128, 189),
                headers: headers.map((columnName) {
                  return TableViewHeader(
                    labelFontSize: 12,
                    label: columnName,
                    padding: const EdgeInsets.all(8),
                    minWidth: columnWidth,
                    alignment: columnName == 'Amount'
                        ? Alignment.centerRight
                        : Alignment.center,
                  );
                }).toList(),
                rows: transactions.map((transaction) {
                  return TableViewRow(
                    height: 55,
                    onTap: () => onRowTap(transaction),
                    cells: [
                      TableViewCell(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          createDocRef(transaction.docType, transaction.docNo,
                              transaction.transDate),
                          softWrap: true,
                        ),
                      ),
                      TableViewCell(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.centerLeft,
                        child:
                            Text(transaction.transactingParty, softWrap: true),
                      ),
                      TableViewCell(
                        alignment: Alignment.centerRight,
                        child: Text(formatAmount(transaction.checkAmount),
                            softWrap: true),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
