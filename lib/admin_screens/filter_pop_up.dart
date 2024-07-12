// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class FilterDialog extends StatefulWidget {
//   @override
//   _FilterDialogState createState() => _FilterDialogState();
// }

// class _FilterDialogState extends State<FilterDialog> {
//   late String _selectedDate;
//   List<String> _docTypes = [];
//   String? _selectedDocType;

//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = _getCurrentDate();
//     _fetchDocTypes();
//   }

//   String _getCurrentDate() {
//     final DateTime now = DateTime.now();
//     return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
//   }

//   Future<void> _fetchDocTypes() async {
//     try {
//       var url = Uri.parse('http://192.168.68.112/localconnect/filter_doctype.php');
//       var response = await http.get(url);

//       if (response.statusCode == 200) {
//         var jsonData = jsonDecode(response.body);
//         if (jsonData is List) {
//           setState(() {
//             _docTypes = List<String>.from(jsonData);
//           });
//         } else {
//           throw Exception('Unexpected response format');
//         }
//       } else {
//         throw Exception('Failed to load document types: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to fetch document types: $e');
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     DateTime initialDate = DateTime.now();
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );

//     if (pickedDate != null && pickedDate != initialDate) {
//       setState(() {
//         _selectedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       child: Container(
//         width: 450,
//         height: 300,
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text("Filter by", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16.0),
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(labelText: "Doc Type"),
//               items: _docTypes.map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: (newValue) {
//                 setState(() {
//                   _selectedDocType = newValue;
//                 });
//               },
//               value: _selectedDocType,
//             ),
//             const SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () => _selectDate(context),
//               child: Text(
//                 "Select Transaction Date: $_selectedDate",
//                 style: const TextStyle(color: Color.fromARGB(255, 49, 31, 31)),
//               ),
//             ),
//             const SizedBox(height: 24.0),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop({
//                   'date': _selectedDate,
//                   'doc_type': _selectedDocType,
//                 });
//               },
//               child: const Text("Apply"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
