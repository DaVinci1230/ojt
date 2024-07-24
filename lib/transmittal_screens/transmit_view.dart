// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'dart:developer' as developer;

// class TransmitView extends StatefulWidget {
//   final List<Map<String, String>> attachments;
//   final Function(int index) onDelete;

//   const TransmitView({
//     Key? key,
//     required this.attachments,
//     required this.onDelete,
//   }) : super(key: key);

//   @override
//   _TransmitViewState createState() => _TransmitViewState();
// }

// class _TransmitViewState extends State<TransmitView> {
//   List<Map<String, String>> _attachments = [];

//   @override
//   void initState() {
//     super.initState();
//     _attachments = List.from(widget.attachments);
//     developer.log('TransmitView initialized with ${_attachments.length} attachments');
//   }

//   void _removeAttachment(int index) {
//     setState(() {
//       _attachments.removeAt(index);
//     });
//     widget.onDelete(index); // Call the callback function
//     developer.log('Attachment removed at index $index');
//   }

//   Future<String> _loadAsset(String path) async {
//     return await rootBundle.loadString(path);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size screenSize = MediaQuery.of(context).size;
//     developer.log('Building TransmitView with ${_attachments.length} attachments');
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color.fromARGB(255, 79, 128, 189),
//         toolbarHeight: 77,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Image.asset(
//                   'assets/logo.png',
//                   width: 60,
//                   height: 55,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'For Uploading',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontFamily: 'Tahoma',
//                     color: Color.fromARGB(255, 233, 227, 227),
//                   ),
//                 ),
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Container(
//                   margin: EdgeInsets.only(right: screenSize.width * 0.02),
//                   child: IconButton(
//                     onPressed: () {
//                       // Navigator.push(
//                       //   context,
//                       //   MaterialPageRoute(
//                       //       builder: (context) => NotificationScreen()),
//                       // );
//                     },
//                     icon: const Icon(
//                       Icons.notifications,
//                       size: 24,
//                       color: Color.fromARGB(255, 233, 227, 227),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {},
//                   icon: const Icon(
//                     Icons.person,
//                     size: 24,
//                     color: Color.fromARGB(255, 233, 227, 227),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
      
//       body: ListView.builder(
//         itemCount: _attachments.length,
//         itemBuilder: (context, index) {
//           final attachment = _attachments[index];
//           developer.log('Building attachment item at index $index');
//           return Dismissible(
//             key: Key(attachment['name']!),
//             onDismissed: (direction) {
//               _removeAttachment(index);
//               // Handle the removal of the attachment
//               // e.g., remove from the database or file system
//               developer.log('Attachment dismissed at index $index');
//             },
//             background: Container(
//               color: Colors.red,
//               alignment: AlignmentDirectional.centerEnd,
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 20),
//                 child: Icon(
//                   Icons.delete,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             child: Container(
//               margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 2,
//                     blurRadius: 5,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.attach_file),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Image.asset(
//                           'assets/${attachment['name']!}',
//                         ),
//                         Text(attachment['status']!),
//                       ],
//                     ),  
//                   ),
//                   if (attachment['status'] == 'Uploaded')
//                     GestureDetector(
//                       onTap: () async {
//                         final imagePath = attachment['path'];
//                         final imageData = await _loadAsset(imagePath!);
//                         developer.log('Showing image preview for ${attachment['name']}');
//                         showDialog(
//                           context: context,
//                           builder: (context) {
//                             return AlertDialog(
//                               title: Text('Image'),
//                               content: Image.memory(base64Decode(imageData)),
//                             );
//                           },
//                         );
//                       },
//                       child: const Icon(Icons.remove_red_eye),
//                     ),
//                   IconButton(
//                     icon: Icon(Icons.delete, color: Colors.red),
//                     onPressed: () {
//                       _removeAttachment(index);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
