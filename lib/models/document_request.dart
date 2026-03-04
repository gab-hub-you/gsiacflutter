enum RequestStatus { pending, underReview, approved, rejected }

class DocumentRequest {
  final String trackingNumber;
  final String type;
  final String purpose;
  final DateTime dateSubmitted;
  final RequestStatus status;
  final String? rejectionReason;
  final String? attachmentPath;

  DocumentRequest({
    required this.trackingNumber,
    required this.type,
    required this.purpose,
    required this.dateSubmitted,
    required this.status,
    this.rejectionReason,
    this.attachmentPath,
  });

  String get statusText {
    switch (status) {
      case RequestStatus.pending: return 'Pending';
      case RequestStatus.underReview: return 'Under Review';
      case RequestStatus.approved: return 'Approved';
      case RequestStatus.rejected: return 'Rejected';
    }
  }
}
