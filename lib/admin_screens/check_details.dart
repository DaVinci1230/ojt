// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import '../models/admin_transaction.dart';

// class CheckDetailsScreen extends StatefulWidget {
//   final Transaction transaction;

//   const CheckDetailsScreen({Key? key, required this.transaction}) : super(key: key);

//   @override
//   _CheckDetailsScreenState createState() => _CheckDetailsScreenState();
// }

// class _CheckDetailsScreenState extends State<CheckDetailsScreen> {
//   late Future<List<Map<String, dynamic>>> _checkDetailsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _checkDetailsFuture = _fetchCheckDetails(widget.transaction.docNo, widget.transaction.docType);
//   }

//   Future<List<Map<String, dynamic>>> _fetchCheckDetails(String docNo, String docType) async {
//     final response = await http.get(Uri.parse('https://backend-approval.azurewebsites.net/view_details.php?doc_no=$docNo&doc_type=$docType'));
//     if (response.statusCode == 200) {
//       List<dynamic> data = json.decode(response.body);
//       return List<Map<String, dynamic>>.from(data);
//     } else {
//       throw Exception('Failed to fetch check details');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final screenWidth = mediaQuery.size.width;

//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: screenWidth * 0.8,
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: FutureBuilder<List<Map<String, dynamic>>>(
//           future: _checkDetailsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else {
//               final List<Map<String, dynamic>> checkDetailsList = snapshot.data!;
//               double totalDebit = 0.0;
//               double totalCredit = 0.0;

//               for (var details in checkDetailsList) {
//                 totalDebit += double.parse(details['debit_amount'] ?? '0');
//                 totalCredit += double.parse(details['credit_amount'] ?? '0');
//               }

//               // Filtered lists for debits and credits
//               List<Map<String, dynamic>> debitList = checkDetailsList
//                   .where((detail) => double.parse(detail['debit_amount'] ?? '0') != 0)
//                   .toList();
//               List<Map<String, dynamic>> creditList = checkDetailsList
//                   .where((detail) => double.parse(detail['credit_amount'] ?? '0') != 0)
//                   .toList();

//               // Determine the maximum length for interleaving
//               int maxLength = (debitList.length > creditList.length) ? debitList.length : creditList.length;

//               return SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Account Description / SL Description',
//                           style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                         ),
//                         Text(
//                           'Amount',
//                           style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 8),
//                     for (int i = 0; i < maxLength; i++)
//                       ...[
//                         if (i < debitList.length) _buildDetailsContainer(debitList[i], true),
//                         if (i < creditList.length) _buildDetailsContainer(creditList[i], false),
//                       ],
//                     SizedBox(height: 12),
//                     Text(
//                       'Status: ${widget.transaction.remarks}',
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ],
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailsContainer(Map<String, dynamic> details, bool isDebit) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.grey[200],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${details['acct_description'] ?? ''}',
//                   style: TextStyle(fontSize: 14),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   '${details['sl_description'] ?? ''}',
//                   style: TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   isDebit
//                       ? '₱ ${NumberFormat('#,###.##').format(double.parse(details['debit_amount'] ?? '0'))} DR'
//                       : '₱ ${NumberFormat('#,###.##').format(double.parse(details['credit_amount'] ?? '0'))} CR',
//                   style: TextStyle(fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
  