import 'package:flutter/material.dart';

enum RequestStatus { 
  pending, 
  verifiedByBarangay, 
  sentToMunicipal, 
  processing, 
  completed, 
  rejected 
}

enum IssuingOffice { barangay, municipal }

class DocumentRequest {
  final String trackingNumber;
  final String type;
  final String purpose;
  final DateTime dateSubmitted;
  final RequestStatus status;
  final IssuingOffice issuingOffice;
  final IssuingOffice currentOffice;
  final String? rejectionReason;
  final String? attachmentPath;

  DocumentRequest({
    required this.trackingNumber,
    required this.type,
    required this.purpose,
    required this.dateSubmitted,
    required this.status,
    required this.issuingOffice,
    required this.currentOffice,
    this.rejectionReason,
    this.attachmentPath,
  });

  String get statusText {
    switch (status) {
      case RequestStatus.pending: return 'Pending Review';
      case RequestStatus.verifiedByBarangay: return 'Verified by Barangay';
      case RequestStatus.sentToMunicipal: return 'Sent to Municipal';
      case RequestStatus.processing: return 'Processing';
      case RequestStatus.completed: return 'Completed';
      case RequestStatus.rejected: return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending: return Colors.orange;
      case RequestStatus.verifiedByBarangay: return Colors.blue;
      case RequestStatus.sentToMunicipal: return Colors.indigo;
      case RequestStatus.processing: return Colors.amber;
      case RequestStatus.completed: return Colors.green;
      case RequestStatus.rejected: return Colors.red;
    }
  }
}
