import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../admin_screens/Admin_Homepage.dart';
import '../models/user_transaction.dart';
import '../screens_user/reprocessing/rep_view_previous.dart';
import '../screens_user/uploading/uploader_hompage.dart';
import '../transmittal_screens/transmitter_homepage.dart';

import 'dart:developer' as developer;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String _baseUrl = 'https://backend-approval.azurewebsites.net/';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  
//ALL VIEWING OF ATTACHMENTS ARE NOT IN THE API. CHECK THE FUNCTION OF
//ITS OWN MOUDLE FOR CHANGES.

 //UserScreens
 //UserScreens
  //UserScreens
   //UserScreens
    //UserScreens
     //UserScreens
      //UserScreens

       //UserScreens
        //UserScreens
         //UserScreens
          //UserScreens



//UserUpload


  Future<List<dynamic>> fetchTransactions() async {
    final response = await http.get(Uri.parse('${_baseUrl}fetch_transaction_data.php'));

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      } else {
        throw Exception('Data key is missing or is not a map');
      }
    } else {
      throw Exception('Failed to load data. Status code: ${response.statusCode}');
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


// loginScreen.dart
  Future<void> loginUser(
      BuildContext context, String username, String password) async {
    try {
      final url = Uri.parse('${_baseUrl}login.php');
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          String userRank = jsonResponse['user_rank'];
          String approval_access = jsonResponse['approval_access'];

          if (userRank.toLowerCase() == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          } else if (userRank.toLowerCase() == 'user' &&
              approval_access.toLowerCase() == 'uploader') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploaderHomePage()),
            );
          } else if (userRank.toLowerCase() == 'user' &&
              approval_access.toLowerCase() == 'uploader-transmitter') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TransmitterHomePage()),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Login Failed'),
                content: Text(jsonResponse['message']),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception('Failed to authenticate: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to connect to server. Error: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  

//disbursement_details

Future<void> uploadTransaction(String docType, String docNo, String dateTrans) async {
    try {
      var uri = Uri.parse('${_baseUrl}update_ops_und.php');
      var requestBody =
          'doc_type=${Uri.encodeComponent(docType)}&doc_no=${Uri.encodeComponent(docNo)}&date_trans=${Uri.encodeComponent(dateTrans)}';

      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        if (result['status'] == 'Success') {
          // Handle success case
          print(result['message']); // Optionally log or handle success message
        } else {
          // Handle other cases (e.g., failure)
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Transaction upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading transaction: $e');
    }
  }





  


  //uploader_hompage.dart


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

          fetchedTransactions.sort((a, b) => b.transDate.compareTo(a.transDate));

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


  //user_add_attachment
 Future<Map<String, dynamic>> uploadFile({
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


  //user_send_attachment.dart
 Future<Map<String, dynamic>> uploadTransactionAndFiles({
    required String docType,
    required String docNo,
    required String dateTrans,
    required List<Map<String, dynamic>> attachments,
  }) async {
    try {
      var uri = Uri.parse('${_baseUrl}update_u.php');
      bool allUploadedSuccessfully = true;
      List<String> errorMessages = [];

      for (var attachment in attachments) {
        if (attachment['name'] != null &&
            attachment['bytes'] != null &&
            attachment['size'] != null) {
          var request = http.MultipartRequest('POST', uri);

          request.fields['doc_type'] = docType;
          request.fields['doc_no'] = docNo;
          request.fields['date_trans'] = dateTrans;

          Uint8List fileBytes = base64Decode(attachment['bytes']!);

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: attachment['name'],
            ),
          );

          developer.log('Uploading file: ${attachment['name']}');

          var response = await request.send();

          if (response.statusCode == 200) {
            var responseBody = await response.stream.bytesToString();
            developer.log('Upload response: $responseBody');

            if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
              var result = jsonDecode(responseBody);

              if (result['status'] != 'success') {
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
            errorMessages.add(
                'File upload failed with status: ${response.statusCode}');
            developer.log(
                'File upload failed with status: ${response.statusCode}');
          }
        } else {
          allUploadedSuccessfully = false;
          errorMessages.add('Error: attachment name, bytes or size is null');
          developer.log('Error: attachment name, bytes or size is null');
        }
      }

      if (allUploadedSuccessfully) {
        return {'success': true, 'message': 'All files uploaded successfully!'};
      } else {
        return {
          'success': false,
          'message': 'Error uploading files:\n${errorMessages.join('\n')}'
        };
      }
    } catch (e) {
      developer.log('Error uploading file or transaction: $e');
      return {
        'success': false,
        'message': 'Error uploading file. Please try again later.'
      };
    }
  }

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

//RepSendAttachment
//rep_send_attachments.dart

 Future<Map<String, dynamic>> uploadTransactionOrFile({
    required String docType,
    required String docNo,
    required String dateTrans,
    required List<Map<String, dynamic>> attachments,
    // required List<Map<String, dynamic>> secAttachments,
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
      // for (var secAttachment in secAttachments) {
      //   if (secAttachment['name'] != null &&
      //       secAttachment['bytes'] != null &&
      //       secAttachment['size'] != null) {
      //     var request = http.MultipartRequest('POST', uri);

      //     request.fields['doc_type'] = docType;
      //     request.fields['doc_no'] = docNo;
      //     request.fields['date_trans'] = dateTrans;

      //     var pickedFile = PlatformFile(
      //       name: secAttachment['name']!,
      //       bytes: Uint8List.fromList(utf8.encode(secAttachment['bytes']!)),
      //       size: int.parse(secAttachment['size']!),
      //     );

      //     if (pickedFile.bytes != null) {
      //       request.files.add(
      //         http.MultipartFile.fromBytes(
      //           'file',
      //           pickedFile.bytes!,
      //           filename: pickedFile.name,
      //         ),
      //       );

      //       developer.log('Uploading file: ${pickedFile.name}');

      //       var response = await request.send();

      //       if (response.statusCode == 200) {
      //         var responseBody = await response.stream.bytesToString();
      //         developer.log('Upload response: $responseBody');

      //         if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
      //           var result = jsonDecode(responseBody);

      //           if (result['status'] == 'success') {
      //             secAttachment['status'] = 'Uploaded';
      //             developer.log('secAttachments array after uploading: $secAttachments');
      //           } else {
      //             return {'success': false, 'message': result['message']};
      //           }
      //         } else {
      //           return {'success': false, 'message': 'Invalid response from server'};
      //         }
      //       } else {
      //         return {'success': false, 'message': 'File upload failed with status: ${response.statusCode}'};
      //       }
      //     } else {
      //       return {'success': false, 'message': 'Error: attachment bytes are null or empty'};
      //     }
      //   } else {
      //     return {'success': false, 'message': 'Error: attachment name, bytes or size is null'};
      //   }
      // }

      return {'success': true, 'message': 'All files uploaded successfully!'};
    } catch (e) {
      developer.log('Error uploading file or transaction: $e');
      return {'success': false, 'message': 'Error uploading file. Please try again later.'};
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



//Uploade_history

 Future<List<dynamic>> fetchTransactionDetailsHistory() async {
    var url = Uri.parse('${_baseUrl}transmitter_history.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transaction details: ${response.statusCode}');
    }
  }


//Notification



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
}