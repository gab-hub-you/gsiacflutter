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
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('beneficiary_programs')
          .select();
          
      _programs = (response as List).map((p) => BeneficiaryProgram.fromJson(p)).toList();

      // Synchronize default programs with the database
      final List<Map<String, dynamic>> defaultPrograms = [
        {
          'id': '64a7c06c-8ab8-4e35-9d22-6789b7e9b0d1',
          'name': '4Ps (Pantawid Pamilya)',
          'description': 'A human development measure of the national government that provides conditional cash grants to the poorest of the poor.',
          'type': 'financial',
          'requirements': ['ID Card', 'Barangay Indigency', 'Family Photo'],
          'payment_schedule': 'Monthly',
          'amount': 1500.0,
        },
        {
          'id': 'f2a4b8c1-d9e0-4f3a-a1b2-c3d4e5f6a7b8',
          'name': 'Senior Citizen Social Pension',
          'description': 'Additional government assistance to indigent senior citizens to augment their daily subsistence and medical needs.',
          'type': 'financial',
          'requirements': ['OSCA ID', 'Birth Certificate'],
          'payment_schedule': 'Quarterly',
          'amount': 3000.0,
        },
        {
          'id': '3e4f5a6b-7c8d-9e0f-1a2b-3c4d5e6f7a8b',
          'name': 'TUPAD Program',
          'description': 'Tulong Panghanapbuhay sa Ating Disadvantaged/Displaced Workers is a community-based package of assistance that provides emergency employment.',
          'type': 'financial',
          'requirements': ['Valid ID', 'Certificate of No Income'],
          'payment_schedule': 'Project-based',
          'amount': 5000.0,
        },
        {
          'id': '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
          'name': 'Municipal Scholarship',
          'description': 'Financial assistance for deserving students residing in the municipality to pursue higher education.',
          'type': 'scholarship',
          'requirements': ['Report Card', 'Indigency Certificate', 'Enrollment Form'],
          'payment_schedule': 'Semesteral',
          'amount': 10000.0,
        },
        {
          'id': 'd9f8e7d6-c5b4-a392-8170-6543210fedcb',
          'name': 'AICS (Crisis Assistance)',
          'description': 'Assistance to Individuals in Crisis Situations (AICS) provides immediate help for medical, burial, or transportation needs.',
          'type': 'financial',
          'requirements': ['Medical Certificate', 'Death Certificate', 'Indigency'],
          'payment_schedule': 'One-time',
          'amount': 2000.0,
        },
        {
          'id': 'a1b2c3d4-e5f6-a7b8-c9d0-e1f2a3b4c5d6',
          'name': 'PWD Benefits',
          'description': 'Provides discounts and financial support to Persons with Disabilities to assist with medical and livelihood needs.',
          'type': 'discount',
          'requirements': ['PWD ID', 'Medical Assessment'],
          'payment_schedule': 'Lifetime',
          'amount': null,
        },
        {
          'id': 'b2c3d4e5-f6a7-b8c9-d0e1-f2a3b4c5d6e7',
          'name': 'Farmer\'s Financial Subsidy',
          'description': 'Subsidy for registered farmers to assist with agricultural inputs and livelihood support during lean months.',
          'type': 'financial',
          'requirements': ['RSBSA Registration', 'Valid ID'],
          'payment_schedule': 'Seasonal',
          'amount': 5000.0,
        },
        {
          'id': 'c3d4e5f6-a7b8-c9d0-e1f2-a3b4c5d6e7f8',
          'name': 'Solo Parent Program',
          'description': 'Comprehensive package of social development and welfare services for solo parents and their children.',
          'type': 'discount',
          'requirements': ['Solo Parent ID', 'Birth Certificates of Children'],
          'payment_schedule': 'Annual',
          'amount': 1000.0,
        },
      ];

      for (final prog in defaultPrograms) {
        await _supabase.from('beneficiary_programs').upsert(prog);
      }

      // Re-fetch everything (including any custom DB programs)
      final allResponse = await _supabase
          .from('beneficiary_programs')
          .select();
      _programs = (allResponse as List).map((p) => BeneficiaryProgram.fromJson(p)).toList();
    } catch (e) {
      debugPrint("Error fetching programs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
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
      
      // Upload supporting docs to the verified 'supporting-docs' bucket
      for (var doc in docs) {
        final name = doc['name'] as String;
        final docBytes = doc['bytes'] as Uint8List?;
        final docPath = doc['path'] as String?;

        final fileName = 'beneficiary_${DateTime.now().millisecondsSinceEpoch}_$name';
        final storagePath = '$citizenId/$fileName';
        
        final data = docBytes ?? await File(docPath!).readAsBytes();
        await _supabase.storage.from('supporting-docs').uploadBinary(storagePath, data);
        
        final url = _supabase.storage.from('supporting-docs').getPublicUrl(storagePath);
        uploadedUrls.add(url);
      }

      final trackingId = "BEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      
      final applicationData = {
        'citizen_id': citizenId,
        'program_id': program.id,
        'program_name': program.name,
        'status': 'pending_barangay', // Supabase snake_case enum
        'tracking_id': trackingId,
        'date_submitted': DateTime.now().toIso8601String(),
        'supporting_docs': uploadedUrls,
      };

      await _supabase.from('beneficiary_applications').insert(applicationData);
      
      // Add notification
      await _supabase.from('notifications').insert({
        'user_id': citizenId,
        'title': 'Benefit Application Submitted',
        'message': 'Your application for ${program.name} has been received (TRK: $trackingId).',
        'type': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

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
        'status': BeneficiaryApplication.toSnakeCase(status.name),
        if (remarks != null) 'remarks': remarks,
        if (status == ApplicationStatus.approved) 'approval_date': DateTime.now().toIso8601String(),
        if (status == ApplicationStatus.approved) 'qr_code': "QR-$applicationId",
      };

      await _supabase.from('beneficiary_applications').update(updateData).eq('id', applicationId);
      
      // Notify user
      final citizenIdResult = await _supabase.from('beneficiary_applications').select('citizen_id, program_name').eq('id', applicationId).single();
      final targetCitizenId = citizenIdResult['citizen_id'] as String;
      final progName = citizenIdResult['program_name'] as String;

      await _supabase.from('notifications').insert({
        'user_id': targetCitizenId,
        'title': 'Benefit Status Updated',
        'message': 'Your $progName application status is now ${status.name}.',
        'type': status == ApplicationStatus.approved ? 'success' : (status == ApplicationStatus.rejected ? 'error' : 'info'),
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

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
            'status': BeneficiaryApplication.toSnakeCase(ApplicationStatus.suspended.name),
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
