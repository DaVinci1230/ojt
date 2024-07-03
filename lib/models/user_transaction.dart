class Transaction {
  final String docType;
  final String docNo;
  final String transactingParty;
  final DateTime transDate;
  final double checkAmount;
  final String transactionStatus;
  final String remarks;
  final String checkBankDrawee;
  final String checkNumber;
  final String bankName;
  final String dateTrans;
  String? onlineProcessingStatus; // Make it nullable

  Transaction({
    required this.docType,
    required this.docNo,
    required this.transactingParty,
    required this.transDate,
    required this.checkAmount,
    required this.transactionStatus,
    required this.remarks,
    required this.checkBankDrawee,
    required this.checkNumber,
    required this.bankName,
    required this.dateTrans,
    this.onlineProcessingStatus, // Make it optional in the constructor
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    String dateString = json['date_trans'];
    DateTime parsedDate = DateTime.parse(dateString);

    return Transaction(
      docType: json['doc_type'].toString(),
      docNo: json['doc_no'].toString(),
      transactingParty: json['transacting_party'].toString(),
      transDate: parsedDate,
      checkAmount: double.parse(json['check_amount'].toString()),
      transactionStatus: json['transaction_status'].toString(),
      remarks: json['remarks'].toString(),
      checkBankDrawee: json['check_drawee_bank'].toString(),
      checkNumber: json['check_no'].toString(),
      bankName: json['check_drawee_bank'].toString(),
      dateTrans: json['date_trans'].toString(),
      onlineProcessingStatus: json['online_processing_status'], // Initialize with null safety
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
}
