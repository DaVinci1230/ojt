import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ojt/transmittal_screens/transmittal_notification.dart';
import '../models/user_transaction.dart';
import '../transmittal_screens/transmitter_homepage.dart';
import '../transmittal_screens/transmitter_send_attachment.dart';
import 'rep_send_attachments.dart';
import '../../api_services/transmitter_api.dart';
import 'reprocessing_menu.dart';
import 'uploader_menu.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';


class RepAddAttachments extends StatefulWidget {
  final UserTransaction transaction;

  const RepAddAttachments({
    Key? key,
    required this.transaction,
    required List selectedDetails,
  }) : super(key: key);

  @override
  _RepAddAttachmentsState createState() =>
      _RepAddAttachmentsState();
}

String sanitizeFileName(String fileName) {
  // Define a regular expression that matches non-alphanumeric characters
  final RegExp regExp = RegExp(r'[^a-zA-Z0-9.]');
  // Replace matched characters with an empty string
  return fileName.replaceAll(regExp, '');
}

class _RepAddAttachmentsState extends State<RepAddAttachments> {
  int _selectedIndex = 0; // Initialize with the correct index for Upload
  List<Map<String, dynamic>> attachments = [];
  String? _fileName;
  PlatformFile? _pickedFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  final TransmitterAPI _apiService = TransmitterAPI();

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransmitterHomePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReprocessMenuWindow()),
        );
        break;
    }
  }

  Future<void> _pickFile() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a file source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text('Images'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Local Storage'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromLocalStorage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List> _compressImage(Uint8List imageData) async {
    img.Image? image = img.decodeImage(imageData);
    if (image != null) {
      img.Image resizedImage = img.copyResize(image, width: 800);
      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
    }
    return imageData;
  }

  Future<void> _pickFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      String fileName = sanitizeFileName(photo.name);
      Uint8List imageData = await photo.readAsBytes();
      Uint8List compressedImageData = await _compressImage(imageData);

      setState(() {
        attachments.add({
          'name': fileName,
          'status': 'Selected',
          'bytes': compressedImageData,
          'size': compressedImageData.length,
          'isLoading': true,
          'isUploading': false,
          'uploadProgress': 0.0,
        });
      });

      // Simulate loading time for demo purposes
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          attachments[attachments.length - 1]['isLoading'] =
              false; // End loading state
        });
      });

      developer.log('File picked from camera: $fileName');
    } else {
      developer.log('Camera picking cancelled');
    }
  }

  Future<void> _pickFromImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        String fileName = sanitizeFileName(image.name);
        Uint8List imageData = await image.readAsBytes();
        Uint8List compressedImageData = await _compressImage(imageData);

        setState(() {
          attachments.add({
            'name': fileName,
            'status': 'Selected',
            'bytes': compressedImageData,
            'size': compressedImageData.length,
            'isLoading': true, // Start loading state
            'isUploading': false,
            'uploadProgress': 0.0,
          });
        });

        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            attachments[attachments.length - 1]['isLoading'] =
                false; // End loading state
          });
        });

        developer.log('File picked from images: $fileName');
      }
    } else {
      developer.log('Image picking cancelled');
    }
  }

  Future<void> _pickFromLocalStorage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        String fileName = sanitizeFileName(file.name ?? 'Unknown');
        Uint8List? fileBytes = file.bytes;
        if (fileBytes != null) {
          Uint8List compressedImageData = await _compressImage(fileBytes);

          setState(() {
            attachments.add({
              'name': fileName,
              'status': 'Selected',
              'bytes': compressedImageData,
              'size': compressedImageData.length,
              'isLoading': true, // Start loading state
              'isUploading': false,
              'uploadProgress': 0.0,
            });
          });

          // Simulate loading time for demo purposes
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              attachments[attachments.length - 1]['isLoading'] =
                  false; // End loading state
            });
          });

          developer.log('File picked: $fileName');
        }
      }
    } else {
      developer.log('File picking cancelled');
    }
  }

  Future<void> _uploadFile(PlatformFile pickedFile) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      var result = await TransmitterAPI().uploadFileUploader(
        docType: widget.transaction.docType.toString(),
        docNo: widget.transaction.docNo.toString(),
        dateTrans: widget.transaction.dateTrans.toString(),
        fileName: sanitizeFileName(pickedFile.name),
        fileBytes: pickedFile.bytes!,
      );

      if (result['success']) {
        setState(() {
          attachments
              .removeWhere((element) => element['name'] == pickedFile.name);
          attachments.add({'name': pickedFile.name, 'status': 'Uploaded'});
          developer.log('Attachments array after uploading: $attachments');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
          ),
        );

        // Show success dialog or handle success scenario
      } else {
        _showDialog(
          context,
          'Error',
          result['message'],
        );
        developer.log('File upload failed: ${result['message']}');
      }
    } catch (e) {
      developer.log('Error uploading file: $e');
      _showDialog(
        context,
        'Error',
        'Error uploading file. Please try again later.',
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(Uint8List imageBytes, Map<String, dynamic> attachment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Name: ${attachment['name']}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9, // Adjust the width
            height:
                MediaQuery.of(context).size.height * 0.7, // Adjust the height
            child: InteractiveViewer(
              child: Image.memory(imageBytes),
              boundaryMargin: EdgeInsets.zero,
              minScale: 0.1,
              maxScale: 3.0,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 79, 128, 189),
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
                  margin: EdgeInsets.only(right: screenSize.width * 0.02),
                  child: IconButton(
                    onPressed: () {
                      // Handle notifications button tap
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UploaderMenuWindow()),
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
      ),
      body: Column(
        children: [
          Container(height: 25),
          Container(
            width: screenSize.width - 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 10,
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(24.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              onPressed: _pickFile,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Click to upload',
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      'Max. File Size: 5Mb',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12.0),
          Expanded(
            child: ListView.builder(
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                var attachment = attachments[index];
                Uint8List? bytes = attachment['bytes'] as Uint8List?;
                int sizeInBytes = bytes?.lengthInBytes ?? 0;
                String sizeString;

                if (sizeInBytes >= 1048576) {
                  // Size in MB
                  double sizeInMB = sizeInBytes / 1048576;
                  sizeString = '${sizeInMB.toStringAsFixed(2)} MB';
                } else if (sizeInBytes >= 1024) {
                  // Size in KB
                  double sizeInKB = sizeInBytes / 1024;
                  sizeString = '${sizeInKB.toStringAsFixed(2)} KB';
                } else {
                  // Size in bytes
                  sizeString = '$sizeInBytes bytes';
                }

                bool isLoading = attachment['isLoading'] ?? false;
                bool isUploading = attachment['isUploading'] ?? false;
                double uploadProgress =
                    (attachment['uploadProgress'] ?? 0).toDouble();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    // Rounded corners
                    side: BorderSide(color: Colors.blue, width: 2), // Border
                  ),
                  child: ListTile(
                    leading: isLoading
                        ? const CircularProgressIndicator()
                        : (bytes != null
                            ? Image.memory(
                                bytes,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported)),
                    title: Text(attachment['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Size: $sizeString'),
                        if (isUploading)
                          LinearProgressIndicator(
                            value: uploadProgress / 100,
                            minHeight: 5,
                            color: Colors.green,
                            backgroundColor: Colors.grey[200],
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () {
                            if (bytes != null) {
                              _showImageDialog(bytes, attachment);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              attachments.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isUploading && !isLoading && bytes != null) {
                        _showImageDialog(bytes, attachment);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      attachments.clear();
                    });
                    Navigator.pop(context);
                    developer.log('Discard button pressed');
                  },
                  child: const Text('Discard'),
                ),
                ElevatedButton(
                  onPressed: () {
                    List<Map<String, String>> attachmentsString = attachments
                        .map((attachment) => attachment.map(
                              (key, value) => MapEntry(key, value.toString()),
                            ))
                        .toList();

                    for (var attachment in attachmentsString) {
                      if (attachment['name'] == null ||
                          attachment['name']!.isEmpty) {
                        developer
                            .log('Error: attachment name is null or empty');
                        return;
                      }

                      if (attachment['bytes'] == null) {
                        developer.log('Error: attachment bytes are null');
                        return;
                      }

                      if (attachment['size'] == null ||
                          attachment['size']!.isEmpty ||
                          int.parse(attachment['size']!) <= 0) {
                        developer
                            .log('Error: attachment size is null or invalid');
                        return;
                      }
                    }
                    for (var attachment in attachments) {
                      _uploadFile(PlatformFile(
                        name: attachment['name'],
                        size: attachment['size'],
                        bytes: attachment['bytes'],
                      ));
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RepSendAttachment(
                          transaction: widget.transaction,
                          selectedDetails: [],
                          attachments: attachmentsString,
                          secAttachments: [],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 79, 129, 189),
                  ),
                  child: const Text('Attach File'),
                ),
              ],
            ),
          ),
          if (_isLoading) // Show loading indicator when uploading
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 79, 128, 189),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'No Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}