import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_transaction.dart';
import '../transmittal_screens/rep_add_attachments.dart';
import '../transmittal_screens/reprocess_view_previous_attachments.dart';

import 'dart:developer' as developer;

class TransmitterAPI {
  static final TransmitterAPI _instance = TransmitterAPI._internal();
  static const String _baseUrl = 'https://backend-approval.azurewebsites.net/';

  factory TransmitterAPI() {
    return _instance;
  }

  TransmitterAPI._internal();



//ALL VIEWING OF ATTACHMENTS ARE NOT IN THE API. CHECK THE FUNCTION OF
//ITS OWN MOUDLE FOR CHANGES.

//transmitter_homepage
 Future<List<UserTransaction>> fetchTransactionDetails() async {
    try {
      var url = Uri.parse('${_baseUrl}count_transaction.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<UserTransaction> fetchedTransactions = jsonData
              .map((transaction) => UserTransaction.fromJson(transaction))
              .toList();
          fetchedTransactions
              .sort((a, b) => b.transDate.compareTo(a.transDate));

          return fetchedTransactions;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load transaction details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

Future<int> fetchNotificationCount() async {
  try {
    final response = await http.get(
      Uri.parse('${_baseUrl}notification_count.php'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // Check if 'notification_count' is present and not null
      if (jsonResponse.containsKey('notification_count') &&
          jsonResponse['notification_count'] != null) {
        return jsonResponse['notification_count'];
      } else {
        throw Exception('Notification count is null or not available');
      }
    } else {
      throw Exception('Failed to load notification count');
    }
  } catch (e) {
    throw Exception('Error fetching notification count: $e');
  }
}



  Future<List<UserTransaction>> countNotification() async {
    try {
      var url = Uri.parse('${_baseUrl}notification_approver.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<UserTransaction> fetchedTransactions = jsonData
              .map((transaction) => UserTransaction.fromJson(transaction))
              .toList();

          fetchedTransactions.sort(
              (a, b) => b.onlineProcessDate.compareTo(a.onlineProcessDate));

          return fetchedTransactions;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to load transaction details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }


//Reprocessing


 Future<List<UserTransaction>> fetchTransactions() async {
    try {
      var url = Uri.parse('${_baseUrl}fetch_transaction_data.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('Received data: $jsonData');

        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          var transactionsData = jsonData['data'];
          if (transactionsData is List) {
            return transactionsData
                .map((json) => UserTransaction.fromJson(json))
                .where((transaction) =>
                    transaction.onlineProcessingStatus == 'R' &&
                    transaction.transactionStatus == 'R')
                .toList();
          } else {
            throw Exception('Data is not a List');
          }
        } else {
          throw Exception('Response data format is incorrect');
        }
      } else {
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to connect to server.');
    }
  }


//Reprocess_details.dart

Future<void> uploadTransaction(String docType, String docNo) async {
  try {
    var url = Uri.parse('${_baseUrl}transmit_sendAgain.php');
    var request = http.Request('POST', url);

    var requestBody =
        'doc_type=${Uri.encodeComponent(docType)}&doc_no=${Uri.encodeComponent(docNo)}';

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body = requestBody;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

      if (result['status'] == 'Success') {
        return;
      } else {
        throw Exception(result['message']);
      }
    } else {
      throw Exception('Transaction upload failed with status: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error uploading transaction: $e');
  }
}

//reprocess view attachment

Future<void> removeAttachment(String filePath, String fileName) async {
  try {
    var url = Uri.parse('${_baseUrl}remove_previous_attachment.php');
    final response = await http.post(
      url,
      body: {
        'file_path': filePath,
        'file_name': fileName,
      },
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      print('Server response: $responseData'); // Log the server response
      if (responseData['status'] == 'success') {
        return;
      } else {
        throw Exception('Failed to remove attachment: ${responseData['message']}');
      }
    } else {
      throw Exception('Failed to remove attachment: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error removing attachment: $e');
  }
}


Future<List<Attachment>> fetchAttachments(String docType, String docNo) async {
  try {
    var url = Uri.parse('${_baseUrl}view_attachment.php?doc_type=$docType&doc_no=$docNo');
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



//rep_add_attachments.dart
Future<Map<String, dynamic>> uploadFile({
    required String docType,
    required String docNo,
    required String dateTrans,
    required PlatformFile pickedFile,
  }) async {
    try {
      var uri = Uri.parse('${_baseUrl}upload_asset.php');
      var request = http.MultipartRequest('POST', uri);

      request.fields['doc_type'] = docType;
      request.fields['doc_no'] = docNo;
      request.fields['date_trans'] = dateTrans;

      // Sanitize the filename
      String sanitizedFileName = sanitizeFileName(pickedFile.name);

      // Add the file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pickedFile.bytes!,
          filename: sanitizedFileName,
        ),
      );

      developer.log('Uploading file: ${pickedFile.name}');
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        developer.log('Upload response: $responseBody');

        try {
          var result = jsonDecode(responseBody);
          if (result['status'] == 'success') {
            return {'success': true, 'message': 'File uploaded successfully'};
          } else {
            return {'success': false, 'message': result['message'] ?? 'Unknown error'};
          }
        } catch (e) {
          developer.log('Error parsing upload response: $e');
          return {'success': false, 'message': 'Error parsing response'};
        }
      } else {
        developer.log('File upload failed with status: ${response.statusCode}');
        return {'success': false, 'message': 'File upload failed with status: ${response.statusCode}'};
      }
    } catch (e) {
      developer.log('Error uploading file: $e');
      return {'success': false, 'message': 'Error uploading file. Please try again later.'};
    }
  }



//rep_send_attachments.dart

 Future<Map<String, dynamic>> uploadTransactionOrFile({
    required String docType,
    required String docNo,
    required String dateTrans,
    required List<Map<String, dynamic>> attachments,
    required List<Map<String, dynamic>> secAttachments,
  }) async {
    try {
      var uri = Uri.parse('${_baseUrl}update_u.php');

      // Process attachments
      for (var attachment in attachments) {
        if (attachment['name'] != null &&
            attachment['bytes'] != null &&
            attachment['size'] != null) {
          var request = http.MultipartRequest('POST', uri);

          request.fields['doc_type'] = docType;
          request.fields['doc_no'] = docNo;
          request.fields['date_trans'] = dateTrans;

          var pickedFile = PlatformFile(
            name: attachment['name']!,
            bytes: Uint8List.fromList(utf8.encode(attachment['bytes']!)),
            size: int.parse(attachment['size']!),
          );

          if (pickedFile.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                pickedFile.bytes!,
                filename: pickedFile.name,
              ),
            );

            developer.log('Uploading file: ${pickedFile.name}');

            var response = await request.send();

            if (response.statusCode == 200) {
              var responseBody = await response.stream.bytesToString();
              developer.log('Upload response: $responseBody');

              if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
                var result = jsonDecode(responseBody);

                if (result['status'] == 'success') {
                  attachment['status'] = 'Uploaded';
                  developer.log('Attachments array after uploading: $attachments');
                } else {
                  return {'success': false, 'message': result['message']};
                }
              } else {
                return {'success': false, 'message': 'Invalid response from server'};
              }
            } else {
              return {'success': false, 'message': 'File upload failed with status: ${response.statusCode}'};
            }
          } else {
            return {'success': false, 'message': 'Error: attachment bytes are null or empty'};
          }
        } else {
          return {'success': false, 'message': 'Error: attachment name, bytes or size is null'};
        }
      }

      // Process secAttachments
      for (var secAttachment in secAttachments) {
        if (secAttachment['name'] != null &&
            secAttachment['bytes'] != null &&
            secAttachment['size'] != null) {
          var request = http.MultipartRequest('POST', uri);

          request.fields['doc_type'] = docType;
          request.fields['doc_no'] = docNo;
          request.fields['date_trans'] = dateTrans;

          var pickedFile = PlatformFile(
            name: secAttachment['name']!,
            bytes: Uint8List.fromList(utf8.encode(secAttachment['bytes']!)),
            size: int.parse(secAttachment['size']!),
          );

          if (pickedFile.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                pickedFile.bytes!,
                filename: pickedFile.name,
              ),
            );

            developer.log('Uploading file: ${pickedFile.name}');

            var response = await request.send();

            if (response.statusCode == 200) {
              var responseBody = await response.stream.bytesToString();
              developer.log('Upload response: $responseBody');

              if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
                var result = jsonDecode(responseBody);

                if (result['status'] == 'success') {
                  secAttachment['status'] = 'Uploaded';
                  developer.log('secAttachments array after uploading: $secAttachments');
                } else {
                  return {'success': false, 'message': result['message']};
                }
              } else {
                return {'success': false, 'message': 'Invalid response from server'};
              }
            } else {
              return {'success': false, 'message': 'File upload failed with status: ${response.statusCode}'};
            }
          } else {
            return {'success': false, 'message': 'Error: attachment bytes are null or empty'};
          }
        } else {
          return {'success': false, 'message': 'Error: attachment name, bytes or size is null'};
        }
      }

      return {'success': true, 'message': 'All files uploaded successfully!'};
    } catch (e) {
      developer.log('Error uploading file or transaction: $e');
      return {'success': false, 'message': 'Error uploading file. Please try again later.'};
    }
  }

//RepViewFiles.dart


  // Future<List<Attachment>> fetchAttachmentsREPVIEW({
  //   required String docType,
  //   required String docNo,
  // }) async {
  //   try {
  //     var url = Uri.parse(
  //         '$_baseUrl/view_attachment.php?doc_type=$docType&doc_no=$docNo');
  //     var response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       var jsonData = jsonDecode(response.body);
  //       if (jsonData is List) {
  //         return jsonData
  //             .map((attachment) => Attachment.fromJson(attachment))
  //             .toList();
  //       } else {
  //         throw Exception('Unexpected response format');
  //       }
  //     } else {
  //       throw Exception('Failed to load attachments: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to fetch attachments: $e');
  //   }
  // }





Future<void> removeServerAttachment(String filePath, String fileName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/remove_previous_attachment.php'),
        body: {
          'file_path': filePath,
          'file_name': fileName,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print('Server response: $responseData'); // Log the server response
        if (responseData['status'] == 'success') {
          return; // Success, no need to do anything else
        } else {
          throw Exception(
              'Failed to remove server attachment: ${responseData['message']}');
        }
      } else {
        throw Exception(
            'Failed to remove server attachment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing server attachment: $e');
    }
  }


// Transmittal Screens
// Transmittal Screens
// Transmittal Screens
// Transmittal Screens
// Transmittal Screens
// Transmittal Screens
// Transmittal Screens


// fetch_transmittal_data.dart

Future<List<UserTransaction>> fetchTransactionsTransmit() async {
    try {
      var url = Uri.parse('${_baseUrl}fetch_transaction_data.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('Received data: $jsonData');

        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          var transactionsData = jsonData['data'];
          if (transactionsData is List) {
            return transactionsData
                .map((json) => UserTransaction.fromJson(json))
                .where((transaction) => transaction.onlineProcessingStatus == 'U')
                .toList();
          } else {
            throw Exception('Unexpected data format');
          }
        } else {
          throw Exception('Data key is missing or is not a map');
        }
      } else {
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to connect to server.');
    }
  }




// no_support_transmit.dart



 Future<List<UserTransaction>> fetchTransactionsTransmitNoSupport() async {
    try {
      var url = Uri.parse('${_baseUrl}fetch_transaction_data.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('Received data: $jsonData');

        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          var transactionsData = jsonData['data'];
          if (transactionsData is List) {
            return transactionsData
                .map((json) => UserTransaction.fromJson(json))
                .where((transaction) => transaction.onlineProcessingStatus == 'ND')
                .toList();
          } else {
            throw Exception('Unexpected data format');
          }
        } else {
          throw Exception('Data key is missing or is not a map');
        }
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to connect to server.');
    }
  }

//no support_details Transmit



 Future<Map<String, dynamic>> uploadTransactionTransmitNoSupportDetails(String docType, String docNo, String dateTrans) async {
    var uri = Uri.parse('${_baseUrl}update_ops_tnd.php');
    var request = http.Request('POST', uri);

    var requestBody = 'doc_type=${Uri.encodeComponent(docType)}&doc_no=${Uri.encodeComponent(docNo)}&date_trans=${Uri.encodeComponent(dateTrans)}';

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body = requestBody;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      throw Exception('Transaction upload failed with status: ${response.statusCode}');
    }
  }

// review_data.dart

Future<Map<String, dynamic>> uploadTransactionTransmitReview({
    required String docType,
    required String docNo,
    required String dateTrans,
  }) async {
    var uri = Uri.parse('${_baseUrl}update_ops_t.php');
    var request = http.Request('POST', uri);

    // URL-encode the values
    var requestBody = 'doc_type=${Uri.encodeComponent(docType)}&doc_no=${Uri.encodeComponent(docNo)}&date_trans=${Uri.encodeComponent(dateTrans)}';

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body = requestBody;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      throw Exception('Transaction upload failed with status: ${response.statusCode}');
    }
  }

// no support_details.dart



// view_attachment.dart

// Future<List<Attachment>> fetchAttachmentsUploader(String docType, String docNo) async {
//     final url = Uri.parse('$_baseUrl/view_attachment.php?doc_type=$docType&doc_no=$docNo');
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final jsonData = jsonDecode(response.body);
//       if (jsonData is List) {
//         return jsonData.map((attachment) => Attachment.fromJson(attachment)).toList();
//       } else {
//         throw Exception('Unexpected response format');
//       }
//     } else {
//       throw Exception('Failed to load attachments: ${response.statusCode}');
//     }
//   }











// FOR UPLOADING

// transmitter_homepage.dart
 Future<Map<String, int>> fetchNewNotificationCount() async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}notification_count.php'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'reprocessingCount': jsonResponse['reprocessing_count'] ?? 0,
          'transmittalCount': jsonResponse['transmittal_count'] ?? 0,
          'uploadingCount': jsonResponse['uploading_count'] ?? 0,
        };
      } else {
        throw Exception('Failed to load notification count');
      }
    } catch (e) {
      print('Error fetching notification count: $e');
      return {
        'reprocessingCount': 0,
        'transmittalCount': 0,
        'uploadingCount': 0,
      };
    }
  }

  // Future<List<UserTransaction>> fetchTransactionDetails() async {
  //   try {
  //     var url = Uri.parse('${_baseUrl}count_transaction.php');
  //     var response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       var jsonData = jsonDecode(response.body);
  //       if (jsonData is List) {
  //         List<UserTransaction> fetchedTransactions = jsonData
  //             .map((transaction) => UserTransaction.fromJson(transaction))
  //             .toList();
  //         fetchedTransactions
  //             .sort((a, b) => b.transDate.compareTo(a.transDate));

  //         return fetchedTransactions;
  //       } else {
  //         throw Exception('Unexpected response format');
  //       }
  //     } else {
  //       throw Exception('Failed to load transaction details: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to fetch transaction details: $e');
  //   }
  // }



// Fetching_uploader






 Future<List<UserTransaction>> fetchTransactionsUploader() async {
    try {
      var url = Uri.parse('${_baseUrl}fetch_transaction_data.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('Received data: $jsonData'); // Log the entire response to understand its structure

        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          var transactionsData = jsonData['data'];
          if (transactionsData is List) {
            return transactionsData
                .map((json) => UserTransaction.fromJson(json))
                .where((transaction) =>
                    transaction.transactionStatus == 'R' &&
                    transaction.onlineProcessingStatus == '')
                .toList();
          } else {
            throw Exception('Unexpected data format');
          }
        } else {
          throw Exception('Data key is missing or is not a map');
        }
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to connect to server.');
    }
  }


// uploading_details


  Future<Map<String, dynamic>> uploadTransactionUploaderDetails(String docType, String docNo, String dateTrans) async {
    var uri = Uri.parse('${_baseUrl}transmitter_ops_und.php');
    var request = http.Request('POST', uri);

    var requestBody = 'doc_type=${Uri.encodeComponent(docType)}&doc_no=${Uri.encodeComponent(docNo)}&date_trans=${Uri.encodeComponent(dateTrans)}';

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body = requestBody;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      throw Exception('Transaction upload failed with status: ${response.statusCode}');
    }
  }


// transmitter_add_attachment
 Future<Map<String, dynamic>> uploadFileUploader  ({
    required String docType,
    required String docNo,
    required String dateTrans,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_baseUrl}upload_asset.php'),
      );

      // Add the 'doc_type', 'doc_no', and 'date_trans' fields to the request
      request.fields['doc_type'] = docType;
      request.fields['doc_no'] = docNo;
      request.fields['date_trans'] = dateTrans;

      // Add the file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      developer.log('Uploading file: $fileName');
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        developer.log('Upload response: $responseBody');

        try {
          var result = jsonDecode(responseBody);
          if (result['status'] == 'success') {
            return {'success': true, 'message': 'File uploaded successfully'};
          } else {
            return {'success': false, 'message': result['message']};
          }
        } catch (e) {
          return {'success': false, 'message': 'Error parsing upload response: $e'};
        }
      } else {
        return {'success': false, 'message': 'File upload failed with status: ${response.statusCode}'};
      }
    } catch (e) {
      developer.log('Error uploading file: $e');
      return {'success': false, 'message': 'Error uploading file. Please try again later.'};
    }
  }


// transmitter_send_attachment



Future<bool> uploadTransactionOrFileUploader({
  required String docType,
  required String docNo,
  required String dateTrans,
  required List<Map<String, dynamic>> attachments,
  // required List<Map<String, dynamic>> secAttachments,
}) async {
  try {
    var uri = Uri.parse('${_baseUrl}update_u.php');
    bool allUploadedSuccessfully = true;
    List<String> errorMessages = [];

    // Helper function to handle file upload
    Future<void> handleFileUpload(Map<String, dynamic> attachment) async {
      if (attachment['name'] != null &&
          attachment['bytes'] != null &&
          attachment['size'] != null) {
        var request = http.MultipartRequest('POST', uri);

        request.fields['doc_type'] = docType;
        request.fields['doc_no'] = docNo;
        request.fields['date_trans'] = dateTrans;

        var bytes = base64Decode(attachment['bytes'] as String);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: attachment['name'] as String,
          ),
        );

        developer.log('Uploading file: ${attachment['name']}');

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          developer.log('Upload response: $responseBody');

          if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
            var result = jsonDecode(responseBody);

            if (result['status'] == 'success') {
              developer.log('File uploaded successfully: ${result['message']}');
            } else {
              allUploadedSuccessfully = false;
              errorMessages.add(result['message']);
              developer.log('File upload failed: ${result['message']}');
            }
          } else {
            allUploadedSuccessfully = false;
            errorMessages.add('Invalid response from server');
            developer.log('Invalid response from server: $responseBody');
          }
        } else {
          allUploadedSuccessfully = false;
          errorMessages.add('File upload failed with status: ${response.statusCode}');
          developer.log('File upload failed with status: ${response.statusCode}');
        }
      } else {
        allUploadedSuccessfully = false;
        errorMessages.add('Error: attachment name, bytes or size is null');
        developer.log('Error: attachment name, bytes or size is null');
      }
    }

    // Process attachments
    for (var attachment in attachments) {
      await handleFileUpload(attachment);
    }

   

    if (!allUploadedSuccessfully) {
      throw Exception('Error uploading files:\n${errorMessages.join('\n')}');
    }
    return true;
  } catch (e) {
    developer.log('Error uploading transaction or files: $e');
    throw Exception('Error uploading transaction or files: $e');
  }
}


Future<void> removeNotification(String docNo, String docType) async {
  try {
    var url = Uri.parse('${_baseUrl}remove_notification.php');
    var response = await http.post(url, body: {
      'docNo': docNo,
      'docType': docType,
    });

    if (response.statusCode == 200) {
      // Optionally handle success response
      print('Notification removed successfully');
    } else {
      throw Exception('Failed to remove notification');
    }
  } catch (e) {
    throw Exception('Error removing notification: $e');
  }
}



// uploader_view_files



// hompagemenu

  Future<List<UserTransaction>> fetchTransactionMenu() async {
  try {
    var url = Uri.parse('${_baseUrl}get_transaction.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<UserTransaction> fetchedTransactions = jsonData
            .map((transaction) => UserTransaction.fromJson(transaction))
            .toList();

        fetchedTransactions.sort(
            (a, b) => b.onlineProcessDate.compareTo(a.onlineProcessDate));

        return fetchedTransactions;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load transaction details: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch transaction details: $e');
  }
}





// notification

Future<List<UserTransaction>> loadTransactions() async {
  try {
    var url = Uri.parse('${_baseUrl}transaction_history.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<UserTransaction> fetchedTransactions = jsonData
            .map((transaction) => UserTransaction.fromJson(transaction))
            .toList();
        
        return fetchedTransactions;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load transaction details: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch transaction details: $e');
  }
}

// history


Future<List<UserTransaction>> fetchTransactionsHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transmitter_history.php'),
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<UserTransaction> transactions = jsonData
            .map((transaction) => UserTransaction.fromJson(transaction))
            .toList();
        transactions.sort((a, b) => b.onlineProcessDate.compareTo(a.onlineProcessDate));
        return transactions;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to fetch transactions with status: ${response.statusCode}');
    }
  }


//Transmitter_card_history


  Future<List<dynamic>> fetchCheckDetails(String docNo, String docType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/view_details.php?doc_no=$docNo&doc_type=$docType'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch check details with status: ${response.statusCode}');
    }
  }




  Future<Map<String, dynamic>> fetchFileNameAndPath(String docNo, String docType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get_file.php?doc_no=$docNo&doc_type=$docType'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch file details with status: ${response.statusCode}');
    }
  }

//Transmitter_card_notification

  Future<List<Map<String, dynamic>>> fetchCheckDetailsNotification(String docNo, String docType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/view_details.php?doc_no=$docNo&doc_type=$docType'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch check details with status: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> fetchFileNameAndPathNotification(String docNo, String docType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get_file.php?doc_no=$docNo&doc_type=$docType'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch file details with status: ${response.statusCode}');
    }
  }
}







// }