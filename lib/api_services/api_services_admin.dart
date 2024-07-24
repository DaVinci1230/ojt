
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/admin_screens/view_attachments.dart';
import '../models/admin_transaction.dart';


class ApiServiceAdmin {
  static final ApiServiceAdmin _instance = ApiServiceAdmin._internal();
  static const String _baseUrl = 'https://backend-approval.azurewebsites.net/';

  factory ApiServiceAdmin() {
    return _instance;
  }

  ApiServiceAdmin._internal();



//ALL VIEWING OF ATTACHMENTS ARE NOT IN THE API. CHECK THE FUNCTION OF
//ITS OWN MOUDLE FOR CHANGES.

  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script
  // Approver's Script


// Admin_hompage.dart

  Future<List<Transaction>> fetchTransactionDetails() async {
  try {
    var url = Uri.parse('${_baseUrl}get_transaction.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<Transaction> fetchedTransactions = jsonData
            .map((transaction) => Transaction.fromJson(transaction))
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

Future<List<Transaction>> countNotification() async {
    try {
      var url = Uri.parse('${_baseUrl}notification_approver.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> fetchedTransactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
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

Future<void> approveTransactions(List<Transaction> transactions) async {
  try {
    for (Transaction transaction in transactions) {
      final response = await http.post(
        Uri.parse('${_baseUrl}approve.php'),
        body: {
          'doc_no': transaction.docNo,
          'doc_type': transaction.docType,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          throw Exception('Failed to approve transaction ${transaction.docNo}');
        }
      } else {
        throw Exception('Failed to approve transaction ${transaction.docNo}');
      }
    }
  } catch (e) {
    throw Exception('Error approving transactions: $e');
  }
}



 Future<void> returnTransactions(List<Transaction> transactions, String approverRemarks) async {
  try {
    for (Transaction transaction in transactions) {
      final response = await http.post(
        Uri.parse('${_baseUrl}return.php'),
        body: {
          'doc_no': transaction.docNo,
          'doc_type': transaction.docType,
          'approver_remarks': approverRemarks,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          throw Exception('Failed to return transaction ${transaction.docNo}');
        }
      } else {
        throw Exception('Failed to return transaction ${transaction.docNo}');
      }
    }
  } catch (e) {
    throw Exception('Error returning transactions: $e');
  }
}

Future<void> rejectTransactions(List<Transaction> transactions) async {
  try {
    for (Transaction transaction in transactions) {
      final response = await http.post(
        Uri.parse('${_baseUrl}reject.php'),
        body: {
          'doc_no': transaction.docNo,
          'doc_type': transaction.docType,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          throw Exception('Failed to reject transaction ${transaction.docNo}');
        }
      } else {
        throw Exception('Failed to reject transaction ${transaction.docNo}');
      }
    }
  } catch (e) {
    throw Exception('Error rejecting transactions: $e');
  }
}


// ApproverNotification.dart

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


Future<List<Transaction>> fetchTransactions([String? onlineTransactionStatus]) async {
  try {
    var url = Uri.parse('${_baseUrl}notification_approver.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      print('API Response: $jsonData');

      if (jsonData is List) {
        List<Transaction> fetchedTransactions = jsonData
            .map((transaction) => Transaction.fromJson(transaction))
            .toList();
        List<Transaction> filteredTransactions = fetchedTransactions
            .where((transaction) =>
                (transaction.onlineTransactionStatus == 'T' ||
                    transaction.onlineTransactionStatus == 'TND'))
            .toList();

        print('Filtered Transactions: $filteredTransactions');

        return filteredTransactions;
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


//disbursement_check.dart


   Future<List<Transaction>> fetchTransactionDetailsDisbusrsement(String onlineTransactionStatus) async {
    try {
      var url = Uri.parse('${_baseUrl}get_transaction.php?onlineTransactionStatus=$onlineTransactionStatus');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> fetchedTransactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
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



Future<void> rejectTransactionsDisbursement(List<Transaction> transactions) async {
    try {
      for (Transaction transaction in transactions) {
        final response = await http.post(
          Uri.parse('${_baseUrl}reject.php'),
          body: {
            'doc_no': transaction.docNo,
            'doc_type': transaction.docType,
          },
        );

        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          if (responseData['status'] != 'success') {
            throw Exception('Failed to reject transaction ${transaction.docNo}');
          }
        } else {
          throw Exception('Failed to reject transaction ${transaction.docNo}');
        }
      }
    } catch (e) {
      throw Exception('Error rejecting transactions: $e');
    }
  }



Future<void> approveTransactionsDisbursement(List<Transaction> transactions) async {
  try {
    for (Transaction transaction in transactions) {
      final response = await http.post(
        Uri.parse('${_baseUrl}approve.php'),
        body: {
          'doc_no': transaction.docNo,
          'doc_type': transaction.docType,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          throw Exception('Failed to approve transaction ${transaction.docNo}');
        }
      } else {
        throw Exception('Failed to approve transaction ${transaction.docNo}');
      }
    }
  } catch (e) {
    throw Exception('Error approving transactions: $e');
  }
}



//transactions_history.dart


Future<List<Transaction>> loadTransactions() async {
  try {
    var url = Uri.parse('${_baseUrl}transaction_history.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        List<Transaction> fetchedTransactions = jsonData
            .map((transaction) => Transaction.fromJson(transaction))
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


//View_attachments Approver

Future<List<Attachment>> fetchAttachments(String docType, String docNo) async {
  try {
    var url = Uri.parse('${_baseUrl}view_attachment.php?doc_type=$docType&doc_no=$docNo');
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











//approver_notification card





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


Future<Map<String, dynamic>> approveTransaction(String docNo, String docType) async {
    var uri = Uri.parse('${_baseUrl}approve.php');
    var response = await http.post(uri, body: {
      'doc_no': docNo,
      'doc_type': docType,
    });

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to approve transaction with status: ${response.statusCode}');
    }
  }


  Future<Map<String, dynamic>> returnTransaction(String docNo, String docType, String approverRemarks) async {
    var uri = Uri.parse('${_baseUrl}return.php');
    var response = await http.post(uri, body: {
      'doc_no': docNo,
      'doc_type': docType,
      'approver_remarks': approverRemarks,
    });

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to return transaction with status: ${response.statusCode}');
    }
  }

    Future<Map<String, dynamic>> rejectTransaction(String docNo, String docType) async {
    var uri = Uri.parse('${_baseUrl}reject.php');
    var response = await http.post(uri, body: {
      'doc_no': docNo,
      'doc_type': docType,
    });

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to reject transaction with status: ${response.statusCode}');
    }
  
}

//History CArd


  Future<List<Map<String, dynamic>>> fetchCheckDetailsCardHistory(String docNo, String docType) async {
    var url = Uri.parse('${_baseUrl}view_details.php?doc_no=$docNo&doc_type=$docType');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch check details: ${response.statusCode}');
    }
  }

 Future<Map<String, dynamic>> fetchFileNameAndPath(String docNo, String docType) async {
    var url = Uri.parse('${_baseUrl}get_file.php?doc_no=$docNo&doc_type=$docType');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch file details: ${response.statusCode}');
    }
  } 



}
