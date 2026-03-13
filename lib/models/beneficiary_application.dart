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
      citizenId: json['citizenId'],
      programId: json['programId'],
      programName: json['programName'] ?? 'Social Program',
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.pendingBarangay,
      ),
      trackingId: json['trackingId'],
      dateSubmitted: DateTime.parse(json['dateSubmitted']),
      supportingDocs: List<String>.from(json['supportingDocs'] ?? []),
      qrCode: json['qrCode'],
      remarks: json['remarks'],
      approvalDate: json['approvalDate'] != null ? DateTime.parse(json['approvalDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizenId': citizenId,
      'programId': programId,
      'programName': programName,
      'status': status.name,
      'trackingId': trackingId,
      'dateSubmitted': dateSubmitted.toIso8601String(),
      'supportingDocs': supportingDocs,
      'qrCode': qrCode,
      'remarks': remarks,
      'approvalDate': approvalDate?.toIso8601String(),
    };
  }
}
