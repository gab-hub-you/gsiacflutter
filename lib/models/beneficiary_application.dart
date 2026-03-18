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
      status: ApplicationStatus.values.firstWhere(
        (e) => fromSnakeCase(json['status']) == e.name,
        orElse: () => ApplicationStatus.pendingBarangay,
      ),
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
      'status': toSnakeCase(status.name),
      'tracking_id': trackingId,
      'date_submitted': dateSubmitted.toIso8601String(),
      'supporting_docs': supportingDocs,
      'qr_code': qrCode,
      'remarks': remarks,
      'approval_date': approvalDate?.toIso8601String(),
    };
  }

  static String toSnakeCase(String name) {
    if (name == 'pendingBarangay') return 'pending_barangay';
    if (name == 'pendingMunicipal') return 'pending_municipal';
    return name;
  }

  static String fromSnakeCase(String? name) {
    if (name == 'pending_barangay') return 'pendingBarangay';
    if (name == 'pending_municipal') return 'pendingMunicipal';
    return name ?? '';
  }
}
