import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';

class RepViewFiles extends StatefulWidget {
  final List<Map<String, String>> attachments;
  final Function(int index) onDelete;
  final String docType;
  final String docNo;

  RepViewFiles({
    Key? key,
    required this.docType,
    required this.docNo,
    required this.attachments,
    required this.onDelete,
  }) : super(key: key);

  @override
  _RepViewFilesState createState() => _RepViewFilesState();
}

class _RepViewFilesState extends State<RepViewFiles> {
  late List<Map<String, String>> _localAttachments;
  late Future<List<Attachment>> _serverAttachmentsFuture;

  @override
  void initState() {
    super.initState();
    _localAttachments = List.from(widget.attachments);
    _serverAttachmentsFuture = _fetchAttachments();
  }

  void _removeLocalAttachment(int index) {
    setState(() {
      _localAttachments.removeAt(index);
    });
    widget.onDelete(index); // Call the callback function
    developer.log('Local attachment removed at index $index');
  }

  Future<List<Attachment>> _fetchAttachments() async {
    try {
      var url = Uri.parse(
          'http://192.168.131.94/localconnect/view_attachment.php?doc_type=${widget.docType}&doc_no=${widget.docNo}');
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
        'assets/$fileName',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attachments'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_localAttachments.isNotEmpty)
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _localAttachments.length,
                itemBuilder: (context, index) {
                  final attachment = _localAttachments[index];
                  developer
                      .log('Building local attachment item at index $index');
                  return Dismissible(
                    key: Key(attachment['name']!),
                    onDismissed: (direction) {
                      _removeLocalAttachment(index);
                      developer
                          .log('Local attachment dismissed at index $index');
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
                      margin:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                          Icon(Icons.attach_file),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/${attachment['name']!}',
                                ),
                                Text(attachment['status']!),
                              ],
                            ),
                          ),
                          if (attachment['status'] == 'Uploaded')
                            GestureDetector(
                              onTap: () async {
                                final imagePath = attachment['path'];
                                final imageData =
                                    await _loadAsset(imagePath!);
                                developer.log(
                                    'Showing image preview for ${attachment['name']}');
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Image'),
                                      content: Image.memory(
                                          base64Decode(imageData)),
                                    );
                                  },
                                );
                              },
                              child: const Icon(Icons.remove_red_eye),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeLocalAttachment(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_localAttachments.isEmpty)
              Center(child: Text('No local attachments found!')),
            FutureBuilder<List<Attachment>>(
              future: _serverAttachmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No server attachments found!'));
                } else {
                  var serverAttachments = snapshot.data!;
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: serverAttachments.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(serverAttachments[index].fileName),
                          subtitle: _buildAttachmentWidget(
                              serverAttachments[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeServerAttachment(index);
                            },
                          ),
                          onTap: () {
                            // Handle server attachment tap
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }

  void _removeServerAttachment(int index) async {
    try {
      Attachment attachment = (await _serverAttachmentsFuture)[index];
      final response = await http.post(
        Uri.parse(
            'http://192.168.131.94/localconnect/remove_previous_attachment.php'),
        body: {
          'file_path': attachment.filePath,
          'file_name': attachment.fileName,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print('Server response: $responseData'); // Log the server response
        if (responseData['status'] == 'success') {
          setState(() {
            _serverAttachmentsFuture = _fetchAttachments();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server attachment removed successfully')),
          );
        } else {
          throw Exception(
              'Failed to remove server attachment: ${responseData['message']}');
        }
      } else {
        throw Exception(
            'Failed to remove server attachment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing server attachment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing server attachment: $e')),
      );
    }
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