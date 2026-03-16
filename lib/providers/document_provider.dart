import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_request.dart';

class DocumentProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<DocumentRequest> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  List<DocumentRequest> get requests => [..._requests];
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;

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
        
        uploadedUrl = _supabase.storage.from('verification-docs').getPublicUrl(path);
      }

      final trackingNumber = "TRK-${DateTime.now().millisecondsSinceEpoch}";
      
      final requestData = {
        'tracking_number': trackingNumber,
        'citizen_id': citizenId,
        'type': type,
        'purpose': purpose,
        'status': RequestStatus.pending.name,
        'issuing_office': office.name,
        'current_office': IssuingOffice.barangay.name,
        'attachment_path': uploadedUrl,
        'date_submitted': DateTime.now().toIso8601String(),
      };

      await _supabase.from('document_requests').insert(requestData);
      
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
        await fetchRequests(refreshCitizenId);
      } else {
        await fetchAllRequests();
      }
    } catch (e) {
      debugPrint("Error forwarding to municipal: $e");
    }
  }

  Future<void> fetchRequests(String citizenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('document_requests')
          .select()
          .eq('citizen_id', citizenId)
          .order('date_submitted', ascending: false);
      
      _requests.clear();
      _requests.addAll((response as List).map((r) => DocumentRequest.fromJson(r)).toList());
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
