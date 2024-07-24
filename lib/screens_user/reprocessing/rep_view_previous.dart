import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '/api_services/transmitter_api.dart';

class RepViewPrevious extends StatefulWidget {
  final String docType;
  final String docNo;

  RepViewPrevious({
    required this.docType,
    required this.docNo,
  });

  @override
  _RepViewPreviousState createState() =>
      _RepViewPreviousState();
}

class _RepViewPreviousState
    extends State<RepViewPrevious> {
  late Future<List<Attachment>> _attachmentsFuture;
final TransmitterAPI _apiService = TransmitterAPI();
  @override
  void initState() {
    super.initState();
    _attachmentsFuture = fetchAttachments as Future<List<Attachment>>;
  }

Widget _buildAttachmentWidget(Attachment attachment) {
    String fileName = attachment.fileName.toLowerCase();
    String fileUrl =
        'https://backend-approval.azurewebsites.net/getpics.php?docType=${Uri.encodeComponent(widget.docType)}&docNo=${Uri.encodeComponent(widget.docNo)}';

    if (fileName.endsWith('.jpeg') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.png')) {
      return Image.network(
        fileUrl,
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.62,
        fit: BoxFit.fill,
      );
    } else if (fileName.endsWith('.pdf')) {
      return FutureBuilder(
        future: _getPdfFile(fileUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.52,
              child: PDFView(
                filePath: snapshot.data!,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                swipeHorizontal: true,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading PDF: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      );
    } else {
      return Center(child: Text('Unsupported file type'));
    }
  }

  Future<String> _getPdfFile(String filePath) async {
    try {
      return filePath;
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  void _showAttachmentDetails(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: _buildAttachmentWidget(
                  Attachment(
                    fileName: fileName,
                    filePath: filePath,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _downloadFile(filePath, fileName),
                child: Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      var dir = await getApplicationDocumentsDirectory();
      String fullPath = "${dir.path}/$fileName";
      Dio dio = Dio();
      await dio.download(fileUrl, fullPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  void _confirmRemoveAttachment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text(
            'This file will be deleted from database.\nAre you sure to remove this file?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeAttachment(index);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

void _removeAttachment(int index) async {
  try {
    Attachment attachment = (await _attachmentsFuture)[index];
    await _apiService.removeAttachment(attachment.filePath, attachment.fileName);

    setState(() {
      _attachmentsFuture = fetchAttachments as Future<List<Attachment>>;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attachment removed successfully')),
    );
  } catch (e) {
    print('Error removing attachment: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error removing attachment: $e')),
    );
  }
}



Future<List<Attachment>> fetchAttachments(String docType, String docNo) async {
  try {
    var url = Uri.parse('https://backend-approval.azurewebsites.net/view_attachment.php?doc_type=$docType&doc_no=$docNo');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<Attachment> fetchedAttachments = jsonData
            .map((attachment) => Attachment.fromJson(attachment))
            .toList();
        
        return fetchedAttachments;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load attachments: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch attachments: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 79, 128, 189),
        toolbarHeight: 77,
        title: Text(
          'Attachments',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Attachment>>(
        future: _attachmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No attachments found!'));
          } else {
            var attachments = snapshot.data!;
            return ListView.builder(
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(attachments[index].fileName),
                    subtitle: _buildAttachmentWidget(attachments[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _confirmRemoveAttachment(index);
                      },
                    ),
                    onTap: () => _showAttachmentDetails(
                      attachments[index].fileName,
                      attachments[index].filePath,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Attachment {
  final String fileName;
  final String filePath;

  Attachment({
    required this.fileName,
    required this.filePath,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileName: json['file_name'].toString(),
      filePath: json['file_path'].toString(),
    );
  }
}
