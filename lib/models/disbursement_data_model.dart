// class DisbursementDetails {
//   final String id;
//   final String transactingParty;
//   final String docType;
//   final String docNo;
//   final String transTypeDescription;
//   final String checkAmount;
//   final String transactionStatus;
//   final String remarks;

//   DisbursementDetails({
//     required this.id,
//     required this.transactingParty,
//     required this.docType,
//     required this.docNo,
//     required this.transTypeDescription,
//     required this.checkAmount,
//     required this.transactionStatus,
//     required this.remarks,
//   });

//   factory DisbursementDetails.fromJson(Map<String, dynamic> json) {
//     return DisbursementDetails(
//       id: json['id'],
//       transactingParty: json['transacting_party'],
//       docType: json['doc_type'],
//       docNo: json['doc_no'],
//       transTypeDescription: json['trans_type_description'],
//       checkAmount: json['check_amount'],
//       transactionStatus: json['transaction_status'],
//       remarks: json['remarks'],
//     );
//   }
// }
