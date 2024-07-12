
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_transaction.dart';


class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String _baseUrl = 'http://192.168.131.94/localconnect/';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<List<Transaction>> fetchTransactionDetails() async {
    try {
      var url = Uri.parse('${_baseUrl}get_transaction.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          List<Transaction> transactions = jsonData
              .map((transaction) => Transaction.fromJson(transaction))
              .toList();
          return transactions;
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

  Future<void> approveTransaction(Transaction transaction) async {
    try {
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
    } catch (e) {
      throw Exception('Error approving transaction: $e');
    }
  }

  Future<void> rejectTransaction(Transaction transaction) async {
    try {
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
    } catch (e) {
      throw Exception('Error rejecting transaction: $e');
    }
  }
}
