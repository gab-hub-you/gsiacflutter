import 'package:flutter/material.dart';

enum ApplicationStatus {
  pendingBarangay,
  pendingMunicipal,
  approved,
  rejected,
  suspended,
}

class BeneficiaryApplication {
  final String id;
  final String citizenId;
  final String programId;
  final String programName;
  final ApplicationStatus status;
  final String trackingId;
  final DateTime dateSubmitted;
  final List<String> supportingDocs;
  final String? qrCode;
  final String? remarks;
  final DateTime? approvalDate;

  BeneficiaryApplication({
    required this.id,
    required this.citizenId,
    required this.programId,
    required this.programName,
    required this.status,
    required this.trackingId,
    required this.dateSubmitted,
    required this.supportingDocs,
    this.qrCode,
    this.remarks,
    this.approvalDate,
  });

  factory BeneficiaryApplication.fromJson(Map<String, dynamic> json) {
    return BeneficiaryApplication(
      id: json['id'],
      citizenId: json['citizen_id'],
      programId: json['program_id'],
      programName: json['program_name'] ?? 'Social Program',
      status: BeneficiaryApplication.statusFromDb(json['status']),
      trackingId: json['tracking_id'],
      dateSubmitted: DateTime.parse(json['date_submitted']),
      supportingDocs: List<String>.from(json['supporting_docs'] ?? []),
      qrCode: json['qr_code'],
      remarks: json['remarks'],
      approvalDate: json['approval_date'] != null ? DateTime.parse(json['approval_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_id': citizenId,
      'program_id': programId,
      'program_name': programName,
      'status': BeneficiaryApplication.statusToDb(status),
      'tracking_id': trackingId,
      'date_submitted': dateSubmitted.toIso8601String(),
      'supporting_docs': supportingDocs,
      'qr_code': qrCode,
      'remarks': remarks,
      'approval_date': approvalDate?.toIso8601String(),
    };
  }

  static ApplicationStatus statusFromDb(String? dbStatus) {
    switch (dbStatus) {
      case 'pending_barangay': return ApplicationStatus.pendingBarangay;
      case 'pending_municipal': return ApplicationStatus.pendingMunicipal;
      case 'approved': return ApplicationStatus.approved;
      case 'rejected': return ApplicationStatus.rejected;
      case 'suspended': return ApplicationStatus.suspended;
      default: return ApplicationStatus.pendingBarangay;
    }
  }

  static String statusToDb(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pendingBarangay: return 'pending_barangay';
      case ApplicationStatus.pendingMunicipal: return 'pending_municipal';
      case ApplicationStatus.approved: return 'approved';
      case ApplicationStatus.rejected: return 'rejected';
      case ApplicationStatus.suspended: return 'suspended';
    }
  }

  String get statusText {
    switch (status) {
      case ApplicationStatus.pendingBarangay: return 'Pending Barangay';
      case ApplicationStatus.pendingMunicipal: return 'Pending Municipal';
      case ApplicationStatus.approved: return 'Approved';
      case ApplicationStatus.rejected: return 'Rejected';
      case ApplicationStatus.suspended: return 'Suspended';
    }
  }

  Color get statusColor {
    switch (status) {
      case ApplicationStatus.pendingBarangay: return Colors.orange;
      case ApplicationStatus.pendingMunicipal: return Colors.indigo;
      case ApplicationStatus.approved: return Colors.green;
      case ApplicationStatus.rejected: return Colors.red;
      case ApplicationStatus.suspended: return Colors.grey;
    }
  }
}
