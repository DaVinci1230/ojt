import 'dart:convert';
import 'dart:io'; // Add this line
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as Img;

class ViewAttachments extends StatefulWidget {
  final String docType;
  final String docNo;

  ViewAttachments({required this.docType, required this.docNo});

  @override
  _ViewAttachmentsState createState() => _ViewAttachmentsState();
}

class _ViewAttachmentsState extends State<ViewAttachments> {
  late Future<List<Attachment>> _attachmentsFuture;

  @override
  void initState() {
    super.initState();
    _attachmentsFuture = _fetchAttachments();
  }

  Future<List<Attachment>> _fetchAttachments() async {
    try {
      var url = Uri.parse(
          'http://192.168.68.116/localconnect/view_attachment.php?doc_type=${widget.docType}&doc_no=${widget.docNo}');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData
              .map((attachment) => Attachment.fromJson(attachment))
              .toList();
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

  Widget _buildAttachmentWidget(Attachment attachment) {
    String fileName = attachment.fileName.toLowerCase();
    if (fileName.endsWith('.jpeg') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.png')) {
      return Image.asset(
        'assets/${attachment.fileName}', // Correctly formatted asset path
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.62,
        fit: BoxFit.fill,
      );
    } else if (fileName.endsWith('.pdf')) {
      return FutureBuilder(
        future: _getPdfFile(attachment.filePath),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: _buildAttachmentWidget(
                Attachment(fileName: fileName, filePath: filePath),
              ),
            ),
            ElevatedButton(
              onPressed: () => _downloadFile(filePath, fileName),
              child: Text('Download'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      Directory? dir = await getApplicationDocumentsDirectory();
      if (dir != null) {
        String fullPath = "${dir.path}/$fileName";
        Dio dio = Dio();
        await dio.download(fileUrl, fullPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fileName to $fullPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get the application directory')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 9, 41, 145),
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
                  child: GestureDetector(
                    onTap: () => _showAttachmentDetails(
                      attachments[index].fileName,
                      attachments[index].filePath,
                    ),
                    child: ListTile(
                      title: Text(attachments[index].fileName),
                      subtitle: _buildAttachmentWidget(attachments[index]),
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

  Attachment({required this.fileName, required this.filePath});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileName: json['file_name'],
      filePath: json['file_path'],
    );
  }
}
