import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:developer' as developer;

class TransmitView extends StatefulWidget {
  final List<Map<String, dynamic>> attachments;
  final Function(int index) onDelete;

  const TransmitView({
    Key? key,
    required this.attachments,
    required this.onDelete,
  }) : super(key: key);

  @override
  _TransmitViewState createState() => _TransmitViewState();
}

class _TransmitViewState extends State<TransmitView> {
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.attachments);
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    widget.onDelete(index); // Call the callback function
  }

  void _showImagePreview(int index) async {
    final attachment = _attachments[index];
    final path = attachment['path'];
    final name = attachment['name'];
    final filePath = '/data/user/0/com.example.leadsolutions/cache/$name';
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        final imageData = await file.readAsBytes();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Image Preview'),
              content: Image.memory(imageData),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: $filePath'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File path is null'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  'For Uploading',
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
                  margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.02),
                  child: IconButton(
                    onPressed: () {
                      // Handle notifications
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
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
      body: ListView.builder(
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          final filePath = attachment['path'];
          final fileName = attachment['name'];

          return Dismissible(
            key: Key(fileName ?? 'attachment_$index'),
            onDismissed: (direction) {
              _removeAttachment(index);
            },
            background: Container(
              color: Colors.red,
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (filePath != null && File(filePath).existsSync())
                    Image.file(
                      File(filePath),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  else
                    Icon(Icons.image_not_supported),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName ?? 'No Name'),
                        Text(attachment['status'] ?? 'Unknown status'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_red_eye),
                    onPressed: () => _showImagePreview(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _removeAttachment(index);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
