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

  factory DocumentRequest.fromJson(Map<String, dynamic> json) {
    return DocumentRequest(
      trackingNumber: json['tracking_number'],
      type: json['type'],
      purpose: json['purpose'],
      dateSubmitted: DateTime.parse(json['date_submitted']),
      status: _statusFromDb(json['status']),
      issuingOffice: _officeFromDb(json['issuing_office']),
      currentOffice: _officeFromDb(json['current_office']),
      rejectionReason: json['rejection_reason'],
      attachmentPath: json['attachment_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_number': trackingNumber,
      'type': type,
      'purpose': purpose,
      'date_submitted': dateSubmitted.toIso8601String(),
      'status': _statusToDb(status),
      'issuing_office': issuingOffice.name,
      'current_office': currentOffice.name,
      'rejection_reason': rejectionReason,
      'attachment_path': attachmentPath,
    };
  }

  static RequestStatus _statusFromDb(String? dbStatus) {
    switch (dbStatus) {
      case 'pending': return RequestStatus.pending;
      case 'verified_by_barangay': return RequestStatus.verifiedByBarangay;
      case 'sent_to_municipal': return RequestStatus.sentToMunicipal;
      case 'processing': return RequestStatus.processing;
      case 'completed': return RequestStatus.completed;
      case 'rejected': return RequestStatus.rejected;
      default: return RequestStatus.pending;
    }
  }

  static String _statusToDb(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return 'pending';
      case RequestStatus.verifiedByBarangay: return 'verified_by_barangay';
      case RequestStatus.sentToMunicipal: return 'sent_to_municipal';
      case RequestStatus.processing: return 'processing';
      case RequestStatus.completed: return 'completed';
      case RequestStatus.rejected: return 'rejected';
    }
  }

  static IssuingOffice _officeFromDb(String? office) {
    if (office == 'municipal') return IssuingOffice.municipal;
    return IssuingOffice.barangay;
  }

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
