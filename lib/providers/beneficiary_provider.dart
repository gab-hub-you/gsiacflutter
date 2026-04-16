import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/beneficiary_program.dart';
import '../models/beneficiary_application.dart';

class BeneficiaryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  List<BeneficiaryProgram> _programs = [];
  List<BeneficiaryApplication> _applications = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Pagination
  static const int _pageSize = 20;
  bool _hasMore = true;

  // Realtime
  RealtimeChannel? _realtimeChannel;

  List<BeneficiaryProgram> get programs => _programs;
  List<BeneficiaryApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;

  /// Subscribes to application changes in real-time.
  void subscribeToApplications(String citizenId) {
    unsubscribeFromRealtime();

    _realtimeChannel = _supabase
        .channel('public:beneficiary_applications:$citizenId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'beneficiary_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'citizen_id',
            value: citizenId,
          ),
          callback: (payload) {
            debugPrint("Realtime update for beneficiary_applications: ${payload.eventType}");
            refreshApplications(citizenId);
          },
        )
        .subscribe();
  }

  void unsubscribeFromRealtime() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }

  BeneficiaryProvider() {
    fetchPrograms();
  }

  /// Fetches programs from the database (no more hardcoded seeding).
  Future<void> fetchPrograms() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('beneficiary_programs')
          .select();
          
      _programs = (response as List).map((p) => BeneficiaryProgram.fromJson(p)).toList();
    } catch (e) {
      debugPrint("Error fetching programs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches paginated applications for a specific citizen.
  Future<void> fetchApplications(String citizenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final from = _applications.length;
      final to = from + _pageSize - 1;

      final response = await _supabase
          .from('beneficiary_applications')
          .select()
          .eq('citizen_id', citizenId)
          .order('date_submitted', ascending: false)
          .range(from, to);
      
      final newItems = (response as List).map((a) => BeneficiaryApplication.fromJson(a)).toList();

      if (from == 0) {
        _applications.clear();
      }
      _applications.addAll(newItems);
      _hasMore = newItems.length >= _pageSize;
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page of applications.
  Future<void> fetchMoreApplications(String citizenId) async {
    if (!_hasMore || _isLoading) return;
    await fetchApplications(citizenId);
  }

  void _resetPagination() {
    _applications.clear();
    _hasMore = true;
  }

  /// Refreshes from the beginning (pull-to-refresh).
  Future<void> refreshApplications(String citizenId) async {
    _resetPagination();
    await fetchApplications(citizenId);
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

  /// Generates a signed URL valid for 1 hour.
  Future<String> _getSignedUrl(String bucket, String path) async {
    return await _supabase.storage
        .from(bucket)
        .createSignedUrl(path, 3600);
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
      
      // Upload supporting docs with signed URLs
      for (var doc in docs) {
        final name = doc['name'] as String;
        final docBytes = doc['bytes'] as Uint8List?;
        final docPath = doc['path'] as String?;

        final fileName = 'beneficiary_${DateTime.now().millisecondsSinceEpoch}_$name';
        final storagePath = '$citizenId/$fileName';
        
        final data = docBytes ?? await File(docPath!).readAsBytes();
        await _supabase.storage.from('supporting-docs').uploadBinary(storagePath, data);
        
        final url = await _getSignedUrl('supporting-docs', storagePath);
        uploadedUrls.add(url);
      }

      // UUID-based tracking ID
      final trackingId = "BEN-${_uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase()}";
      
      final applicationData = {
        'citizen_id': citizenId,
        'program_id': program.id,
        'program_name': program.name,
        // Status is handled by the database default (pending_barangay)
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

      // Reset and refresh
      _resetPagination();
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
        'status': BeneficiaryApplication.statusToDb(status),
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
        _resetPagination();
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
            'status': BeneficiaryApplication.statusToDb(ApplicationStatus.suspended),
            'remarks': 'AUTOMATED SYSTEM ACTION: Benefits suspended due to verified death record.',
          })
          .eq('citizen_id', citizenId)
          .eq('status', ApplicationStatus.approved.name);
      
      _resetPagination();
      await fetchApplications(citizenId);
    } catch (e) {
      debugPrint("Error processing death record event: $e");
    }
  }
}
