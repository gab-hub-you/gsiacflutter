import 'package:flutter/material.dart';
import '../models/beneficiary_program.dart';
import '../models/beneficiary_application.dart';

class BeneficiaryProvider extends ChangeNotifier {
  List<BeneficiaryProgram> _programs = [];
  List<BeneficiaryApplication> _applications = [];
  bool _isLoading = false;

  List<BeneficiaryProgram> get programs => _programs;
  List<BeneficiaryApplication> get applications => _applications;
  bool get isLoading => _isLoading;

  BeneficiaryProvider() {
    _loadMocks();
  }

  void _loadMocks() {
    _programs = [
      BeneficiaryProgram(
        id: 'P1',
        name: 'Senior Citizen Pension',
        description: 'Monthly financial assistance for citizens aged 60 and above.',
        requirements: ['Valid Government ID', 'Senior Citizen ID', 'Proof of Residency'],
        type: BenefitType.financial,
        paymentSchedule: 'Every 1st of the Month',
        amount: 1000.0,
      ),
      BeneficiaryProgram(
        id: 'P2',
        name: 'Solo Parent Support',
        description: 'Assistance for single parents providing for their family.',
        requirements: ['Solo Parent ID', 'Birth Certificate of Child', 'Certificate of Indigency'],
        type: BenefitType.financial,
        paymentSchedule: 'Quarterly',
        amount: 3000.0,
      ),
      BeneficiaryProgram(
        id: 'P3',
        name: 'Tertiary Education Scholarship',
        description: 'Educational grant for deserving students from low-income families.',
        requirements: ['Report Card', 'Certificate of Enrollment', 'Income Tax Return of Parents'],
        type: BenefitType.scholarship,
        paymentSchedule: 'Per Semester',
        amount: 15000.0,
      ),
      BeneficiaryProgram(
        id: 'P4',
        name: 'Medical Assistance Program',
        description: 'Financial aid for hospital bills and medication.',
        requirements: ['Medical Certificate', 'Hospital Bill / Prescription', 'Barangay Indigency'],
        type: BenefitType.medical,
        paymentSchedule: 'One-time per case',
      ),
    ];

    _applications = [
      BeneficiaryApplication(
        id: 'A1',
        citizenId: 'user123',
        programId: 'P1',
        programName: 'Senior Citizen Pension',
        status: ApplicationStatus.approved,
        trackingId: 'BEN-882910',
        dateSubmitted: DateTime.now().subtract(const Duration(days: 30)),
        supportingDocs: [],
        qrCode: 'SENIOR-USER123-VALID',
        approvalDate: DateTime.now().subtract(const Duration(days: 25)),
      ),
      BeneficiaryApplication(
        id: 'A2',
        citizenId: 'user123',
        programId: 'P3',
        programName: 'Tertiary Education Scholarship',
        status: ApplicationStatus.pendingMunicipal,
        trackingId: 'BEN-990122',
        dateSubmitted: DateTime.now().subtract(const Duration(days: 5)),
        supportingDocs: ['id.png', 'grades.pdf'],
      ),
    ];
  }

  Future<String> submitApplication({
    required String citizenId,
    required BeneficiaryProgram program,
    required List<String> docs,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final trackingId = "BEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final application = BeneficiaryApplication(
      id: DateTime.now().toIso8601String(),
      citizenId: citizenId,
      programId: program.id,
      programName: program.name,
      status: ApplicationStatus.pendingBarangay,
      trackingId: trackingId,
      dateSubmitted: DateTime.now(),
      supportingDocs: docs,
    );

    _applications.insert(0, application);
    _isLoading = false;
    notifyListeners();
    return trackingId;
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status, {String? remarks}) async {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      final app = _applications[index];
      _applications[index] = BeneficiaryApplication(
        id: app.id,
        citizenId: app.citizenId,
        programId: app.programId,
        programName: app.programName,
        status: status,
        trackingId: app.trackingId,
        dateSubmitted: app.dateSubmitted,
        supportingDocs: app.supportingDocs,
        remarks: remarks ?? app.remarks,
        qrCode: status == ApplicationStatus.approved ? "QR-${app.trackingId}" : app.qrCode,
        approvalDate: status == ApplicationStatus.approved ? DateTime.now() : app.approvalDate,
      );
      notifyListeners();
    }
  }

  // Automation Integration: Death Record Event
  // Simulates an event trigger when a citizen is marked as deceased
  Future<void> processDeathRecordEvent(String citizenId) async {
    bool hasUpdates = false;
    for (int i = 0; i < _applications.length; i++) {
      if (_applications[i].citizenId == citizenId && _applications[i].status == ApplicationStatus.approved) {
        final app = _applications[i];
        _applications[i] = BeneficiaryApplication(
          id: app.id,
          citizenId: app.citizenId,
          programId: app.programId,
          programName: app.programName,
          status: ApplicationStatus.suspended,
          trackingId: app.trackingId,
          dateSubmitted: app.dateSubmitted,
          supportingDocs: app.supportingDocs,
          remarks: 'AUTOMATED SYSTEM ACTION: Benefits suspended due to verified death record.',
          qrCode: app.qrCode, // Keep QR code but it shouldn't be valid, or nullify it
          approvalDate: app.approvalDate,
        );
        hasUpdates = true;
      }
    }
    
    if (hasUpdates) {
      notifyListeners();
      // Normally, notify the Social Welfare Department here via another API
    }
  }
}
