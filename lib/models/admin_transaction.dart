class Transaction {
  final String transactingParty;
  final String transDate;
  final String checkNo;
  final String docType;
  final String docNo;
  final String? fileName; // Nullable
  final String? filePath; // Nullable
  final String uploadedBy;
  final String dateUploaded;
  final String checkAmount;
  final String checkBankDrawee;
  final String checkDate;
  final String remarks;
  bool isSelected;
  String onlineTransactionStatus;
  final String approverRemarks;
  final String transactionStatus;
  final String onlineProcessDate;
  final String notification;

  Transaction({
    required this.transactingParty,
    required this.transDate,
    required this.checkNo,
    required this.docType,
    required this.docNo,
    required this.uploadedBy,
    required this.dateUploaded,
    required this.checkAmount,
    required this.checkBankDrawee,
    required this.checkDate,
    required this.remarks,
    required this.onlineTransactionStatus,
    this.fileName,
    this.filePath,
    this.isSelected = false,
    required this.approverRemarks,
    required this.transactionStatus,
    required this.onlineProcessDate,
    required this.notification,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactingParty: json['transacting_party'] ?? '',
      transDate: json['date_trans'] ?? '',
      checkNo: json['check_no'] ?? '',
      docType: json['doc_type'] ?? '',
      fileName: json['file_name'],
      filePath: json['file_path'],
      uploadedBy: json['uploaded_by'] ?? '',
      dateUploaded: json['date_uploaded'] ?? '',
      checkAmount: json['check_amount'].toString(),
      docNo: json['doc_no'] ?? '',
      checkBankDrawee: json['check_drawee_bank'] ?? '',
      checkDate: json['check_date'] ?? '',
      remarks: json['remarks'] ?? '',
      onlineTransactionStatus: json['online_processing_status'] ?? '',
      approverRemarks: json['approver_remarks'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      onlineProcessDate: json['online_process_date'] ?? '',
      notification: json['notification'] ?? '',
    );
  }

  String get convertTransactionStatus {
    switch (transactionStatus) {
      case 'A':
        return 'Approved';
      case 'R':
        return 'Returned';
      case 'N':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  bool get hasFileName => fileName != null && fileName!.isNotEmpty;
  bool get hasFilePath => filePath != null && filePath!.isNotEmpty;
}

class NotificationCount {
  final int reprocessingCount;
  final int transmittalCount;
  final int uploadingCount;

  NotificationCount({
    required this.reprocessingCount,
    required this.transmittalCount,
    required this.uploadingCount,
  });

  factory NotificationCount.fromJson(Map<String, dynamic> json) {
    return NotificationCount(
      reprocessingCount: json['reprocessing_count'] ?? 0,
      transmittalCount: json['transmittal_count'] ?? 0,
      uploadingCount: json['uploading_count'] ?? 0,
    );
  }
}
