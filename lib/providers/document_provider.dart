import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/document_request.dart';

class DocumentProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final List<DocumentRequest> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Pagination
  static const int _pageSize = 20;
  bool _hasMore = true;

  // Realtime
  RealtimeChannel? _realtimeChannel;

  List<DocumentRequest> get requests => [..._requests];
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;

  /// Subscribes to document request changes in real-time.
  void subscribeToRequests(String citizenId) {
    unsubscribeFromRealtime();

    _realtimeChannel = _supabase
        .channel('public:document_requests:$citizenId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'document_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'citizen_id',
            value: citizenId,
          ),
          callback: (payload) {
            debugPrint("Realtime update for document_requests: ${payload.eventType}");
            // Simple approach: refresh the first page on any change
            refreshRequests(citizenId);
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

  /// Generates a signed URL valid for 1 hour instead of a public URL.
  Future<String> _getSignedUrl(String bucket, String path) async {
    final signedUrl = await _supabase.storage
        .from(bucket)
        .createSignedUrl(path, 3600); // 1 hour expiry
    return signedUrl;
  }

  Future<String> submitRequest({
    required String citizenId,
    required String type,
    required String purpose,
    required IssuingOffice office,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      String? uploadedUrl;
      if (attachmentBytes != null || attachmentPath != null) {
        final name = attachmentFileName ?? attachmentPath?.split('/').last ?? 'attachment';
        final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}_$name';
        final path = '$citizenId/requests/$fileName';
        
        final data = attachmentBytes ?? await File(attachmentPath!).readAsBytes();
        await _supabase.storage.from('verification-docs').uploadBinary(path, data);
        
        uploadedUrl = await _getSignedUrl('verification-docs', path);
      }

      // UUID-based tracking number (first 8 chars of UUID v4)
      final trackingNumber = "TRK-${_uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase()}";
      
      final requestData = {
        'tracking_number': trackingNumber,
        'citizen_id': citizenId,
        'type': type,
        'purpose': purpose,
        // Status is handled by the database default (pending)
        'issuing_office': office.name,
        'current_office': IssuingOffice.barangay.name,
        'attachment_path': uploadedUrl,
        'date_submitted': DateTime.now().toIso8601String(),
      };

      await _supabase.from('document_requests').insert(requestData);
      
      // Add notification
      await _supabase.from('notifications').insert({
        'user_id': citizenId,
        'title': 'Request Submitted',
        'message': 'Your request for $type has been submitted successfully (TRK: $trackingNumber).',
        'type': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      // Reset pagination and fetch fresh
      _resetPagination();
      await fetchRequests(citizenId);
      
      return trackingNumber;
    } catch (e) {
      debugPrint("Error submitting request: $e");
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateRequestStatus(String trk, RequestStatus newStatus, {String? refreshCitizenId}) async {
    try {
      await _supabase
          .from('document_requests')
          .update({'status': newStatus.name})
          .eq('tracking_number', trk);
      
      if (refreshCitizenId != null) {
        await _supabase.from('notifications').insert({
          'user_id': refreshCitizenId,
          'title': 'Request Updated',
          'message': 'Your request $trk status has been updated to ${newStatus.name}.',
          'type': newStatus == RequestStatus.completed ? 'success' : (newStatus == RequestStatus.rejected ? 'error' : 'info'),
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': false,
        });

        _resetPagination();
        await fetchRequests(refreshCitizenId);
      } else {
        await fetchAllRequests();
      }
    } catch (e) {
      debugPrint("Error updating request status: $e");
    }
  }

  Future<void> forwardToMunicipal(String trk, {String? refreshCitizenId}) async {
    try {
      await _supabase
          .from('document_requests')
          .update({
            'status': RequestStatus.sentToMunicipal.name,
            'current_office': IssuingOffice.municipal.name,
          })
          .eq('tracking_number', trk);
      
      if (refreshCitizenId != null) {
        await _supabase.from('notifications').insert({
          'user_id': refreshCitizenId,
          'title': 'Request Forwarded',
          'message': 'Your request $trk has been forwarded to the Municipal Hall for final review.',
          'type': 'warning',
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': false,
        });
        _resetPagination();
        await fetchRequests(refreshCitizenId);
      } else {
        await fetchAllRequests();
      }
    } catch (e) {
      debugPrint("Error forwarding to municipal: $e");
    }
  }

  /// Fetches the first page of requests for a citizen (paginated).
  Future<void> fetchRequests(String citizenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final from = _requests.length;
      final to = from + _pageSize - 1;

      final response = await _supabase
          .from('document_requests')
          .select()
          .eq('citizen_id', citizenId)
          .order('date_submitted', ascending: false)
          .range(from, to);
      
      final newItems = (response as List).map((r) => DocumentRequest.fromJson(r)).toList();
      
      if (from == 0) {
        _requests.clear();
      }
      _requests.addAll(newItems);
      _hasMore = newItems.length >= _pageSize;
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page of requests.
  Future<void> fetchMoreRequests(String citizenId) async {
    if (!_hasMore || _isLoading) return;
    await fetchRequests(citizenId);
  }

  /// Resets pagination state for a fresh fetch.
  void _resetPagination() {
    _requests.clear();
    _hasMore = true;
  }

  /// Refreshes from the beginning (pull-to-refresh).
  Future<void> refreshRequests(String citizenId) async {
    _resetPagination();
    await fetchRequests(citizenId);
  }

  Future<void> fetchAllRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('document_requests')
          .select()
          .order('date_submitted', ascending: false);
      
      _requests.clear();
      _requests.addAll((response as List).map((r) => DocumentRequest.fromJson(r)).toList());
    } catch (e) {
      debugPrint("Error fetching all requests: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
