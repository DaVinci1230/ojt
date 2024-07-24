class UserTransaction {
  final String docType;
  final String docNo;
  final String transactingParty;
  final DateTime transDate;
  final double checkAmount;
  final String checkAm;
  final String transactionStatus;
  final String remarks;
  final String approverRemarks;
  final String checkBankDrawee;
  final String checkNumber;
  final String bankName;
  final String checkDate;
  final String dateTrans;
  String? onlineProcessingStatus;
  String? onlineTransactionStatus;
  final String onlineProcessDate;
  final String notification;

  UserTransaction({
    required this.docType,
    required this.docNo,
    required this.transactingParty,
    required this.transDate,
    required this.checkAm,
    required this.checkAmount,
    required this.transactionStatus,
    required this.remarks,
    required this.approverRemarks,
    required this.checkBankDrawee,
    required this.checkNumber,
    required this.bankName,
    required this.checkDate,
    required this.dateTrans,
    this.onlineProcessingStatus,
    this.onlineTransactionStatus,
    required this.onlineProcessDate,
    required this.notification,
  });

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    String dateString = json['date_trans'] ?? '';
    DateTime parsedDate = dateString.isNotEmpty
        ? DateTime.parse(dateString)
        : DateTime.now(); // Default to current date if empty

    return UserTransaction(
      docType: json['doc_type'].toString(),
      docNo: json['doc_no'].toString(),
      checkAm: json['check_amount'].toString(),
      transactingParty: json['transacting_party'].toString(),
      transDate: parsedDate,
      checkAmount: double.parse(json['check_amount'].toString()),
      transactionStatus: json['transaction_status'].toString(),
      remarks: json['remarks'].toString(),
      approverRemarks: json['approver_remarks'].toString(),
      checkBankDrawee: json['check_drawee_bank'].toString(),
      checkNumber: json['check_no'].toString(),
      bankName: json['check_drawee_bank'].toString(),
      checkDate: json['check_date'] ?? '',
      dateTrans: json['date_trans'].toString(),
      onlineProcessingStatus: json['online_processing_status'],
      onlineTransactionStatus: json['online_transaction_status'],
      onlineProcessDate: json['online_process_date'] ?? '',
      notification: json ['notification'] ?? '',
    );
  }

  String get transactionStatusWord {
    switch (transactionStatus) {
      case 'A':
        return 'Approved';
      case 'R':
        return 'Reviewed';
      case 'S':
        return 'Submitted';
      case 'NS':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get onlineProcessingStatusWord {
    switch (onlineProcessingStatus) {
      case 'A':
        return 'Approved';
      case 'R':
        return 'Returned';
      case 'U':
        return 'On Process';
      case 'ND':
        return 'On Process';
      case 'T':
        return 'On Approval';
      case 'TND':
        return 'On Approval';
      default:
        return 'Rejected';
    }
  }
}
