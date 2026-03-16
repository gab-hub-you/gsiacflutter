import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/beneficiary_program.dart';
import '../models/beneficiary_application.dart';

class BeneficiaryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<BeneficiaryProgram> _programs = [];
  List<BeneficiaryApplication> _applications = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  List<BeneficiaryProgram> get programs => _programs;
  List<BeneficiaryApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;

  BeneficiaryProvider() {
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    try {
      final response = await _supabase.from('beneficiary_programs').select();
      _programs = (response as List).map((p) => BeneficiaryProgram.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching programs: $e");
    }
  }

  Future<void> fetchApplications(String citizenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('beneficiary_applications')
          .select()
          .eq('citizen_id', citizenId)
          .order('date_submitted', ascending: false);
      
      _applications = (response as List).map((a) => BeneficiaryApplication.fromJson(a)).toList();
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllApplications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('beneficiary_applications')
          .select()
          .order('date_submitted', ascending: false);
      
      _applications = (response as List).map((a) => BeneficiaryApplication.fromJson(a)).toList();
    } catch (e) {
      debugPrint("Error fetching all applications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> submitApplication({
    required String citizenId,
    required BeneficiaryProgram program,
    required List<Map<String, dynamic>> docs,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final List<String> uploadedUrls = [];
      
      // Upload supporting docs
      for (var doc in docs) {
        final name = doc['name'] as String;
        final docBytes = doc['bytes'] as Uint8List?;
        final docPath = doc['path'] as String?;

        final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}_$name';
        final storagePath = '$citizenId/applications/$fileName';
        
        final data = docBytes ?? await File(docPath!).readAsBytes();
        await _supabase.storage.from('verification-docs').uploadBinary(storagePath, data);
        
        final url = _supabase.storage.from('verification-docs').getPublicUrl(storagePath);
        uploadedUrls.add(url);
      }

      final trackingId = "BEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      
      final applicationData = {
        'citizen_id': citizenId,
        'program_id': program.id,
        'program_name': program.name,
        'status': ApplicationStatus.pendingBarangay.name,
        'tracking_id': trackingId,
        'date_submitted': DateTime.now().toIso8601String(),
        'supporting_docs': uploadedUrls,
      };

      await _supabase.from('beneficiary_applications').insert(applicationData);
      
      // Refresh applications list
      await fetchApplications(citizenId);
      
      return trackingId;
    } catch (e) {
      debugPrint("Error submitting application: $e");
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status, {String? remarks}) async {
    try {
      final updateData = {
        'status': status.name,
        if (remarks != null) 'remarks': remarks,
        if (status == ApplicationStatus.approved) 'approval_date': DateTime.now().toIso8601String(),
        if (status == ApplicationStatus.approved) 'qr_code': "QR-$applicationId",
      };

      await _supabase.from('beneficiary_applications').update(updateData).eq('id', applicationId);
      
      // Update local state if needed or re-fetch
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        await fetchApplications(_applications[index].citizenId);
      }
    } catch (e) {
      debugPrint("Error updating application status: $e");
    }
  }

  // Automation Integration: Death Record Event
  Future<void> processDeathRecordEvent(String citizenId) async {
    try {
      await _supabase
          .from('beneficiary_applications')
          .update({
            'status': ApplicationStatus.suspended.name,
            'remarks': 'AUTOMATED SYSTEM ACTION: Benefits suspended due to verified death record.',
          })
          .eq('citizen_id', citizenId)
          .eq('status', ApplicationStatus.approved.name);
      
      await fetchApplications(citizenId);
    } catch (e) {
      debugPrint("Error processing death record event: $e");
    }
  }
}
