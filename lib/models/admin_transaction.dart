class Transaction {
  final String transactingParty;
  final String transDate;
  final String checkNo;
  final String docType;
  final String docNo;
  final String fileName;
  final String filePath;
  final String uploadedBy;
  final String dateUploaded;
  final String checkAmount;
  final String checkBankDrawee;
  final String checkDate;
  final String remarks;
  bool isSelected;
  String onlineTransactionStatus;
  final String approverRemarks;

  Transaction({
    required this.transactingParty,
    required this.transDate,
    required this.checkNo,
    required this.docType,
    required this.docNo,
    required this.fileName,
    required this.filePath,
    required this.uploadedBy,
    required this.dateUploaded,
    required this.checkAmount,
    required this.checkBankDrawee,
    required this.checkDate,
    required this.remarks,
    required this.onlineTransactionStatus,
    this.isSelected = false,
    required this.approverRemarks,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactingParty: json['transacting_party'] ?? '',
      transDate: json['date_trans'] ?? '',
      checkNo: json['check_no'] ?? '',
      docType: json['doc_type'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      dateUploaded: json['date_uploaded'] ?? '',
      checkAmount: json['check_amount'].toString(),
      docNo: json['doc_no'] ?? '',
      checkBankDrawee: json['check_drawee_bank'] ?? '',
      checkDate: json['check_date'],
      remarks: json['remarks'] ?? '',
      onlineTransactionStatus: json['online_processing_status'] ?? '',
      approverRemarks: json['approver_remarks'] ?? '',
    );
  }
}
