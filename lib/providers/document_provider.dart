import 'package:flutter/material.dart';
import '../models/document_request.dart';

class DocumentProvider extends ChangeNotifier {
  final List<DocumentRequest> _requests = [];
  bool _isLoading = false;

  List<DocumentRequest> get requests => [..._requests];
  bool get isLoading => _isLoading;

  Future<String> submitRequest({
    required String type,
    required String purpose,
    required IssuingOffice office,
    String? attachmentPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    // MOCK API Call
    await Future.delayed(const Duration(seconds: 1));

    final trackingNumber = "TRK-${DateTime.now().millisecondsSinceEpoch}";
    final newRequest = DocumentRequest(
      trackingNumber: trackingNumber,
      type: type,
      purpose: purpose,
      dateSubmitted: DateTime.now(),
      status: RequestStatus.pending,
      issuingOffice: office,
      currentOffice: IssuingOffice.barangay, // All requests go to Barangay first
      attachmentPath: attachmentPath,
    );

    _requests.insert(0, newRequest);
    _isLoading = false;
    notifyListeners();
    return trackingNumber;
  }

  // Inter-agency workflow methods
  Future<void> updateRequestStatus(String trk, RequestStatus newStatus) async {
    final index = _requests.indexWhere((r) => r.trackingNumber == trk);
    if (index != -1) {
      final r = _requests[index];
      _requests[index] = DocumentRequest(
        trackingNumber: r.trackingNumber,
        type: r.type,
        purpose: r.purpose,
        dateSubmitted: r.dateSubmitted,
        status: newStatus,
        issuingOffice: r.issuingOffice,
        currentOffice: r.currentOffice,
        attachmentPath: r.attachmentPath,
      );
      notifyListeners();
    }
  }

  Future<void> forwardToMunicipal(String trk) async {
    final index = _requests.indexWhere((r) => r.trackingNumber == trk);
    if (index != -1) {
      final r = _requests[index];
      _requests[index] = DocumentRequest(
        trackingNumber: r.trackingNumber,
        type: r.type,
        purpose: r.purpose,
        dateSubmitted: r.dateSubmitted,
        status: RequestStatus.sentToMunicipal,
        issuingOffice: r.issuingOffice,
        currentOffice: IssuingOffice.municipal,
        attachmentPath: r.attachmentPath,
      );
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    if (_requests.isEmpty) {
      _requests.addAll([
        DocumentRequest(
          trackingNumber: "TRK-100200",
          type: "Barangay Clearance",
          purpose: "Employment",
          dateSubmitted: DateTime.now().subtract(const Duration(days: 2)),
          status: RequestStatus.completed,
          issuingOffice: IssuingOffice.barangay,
          currentOffice: IssuingOffice.barangay,
        ),
        DocumentRequest(
          trackingNumber: "TRK-100201",
          type: "Birth Certificate",
          purpose: "Passport Application",
          dateSubmitted: DateTime.now().subtract(const Duration(days: 1)),
          status: RequestStatus.sentToMunicipal,
          issuingOffice: IssuingOffice.municipal,
          currentOffice: IssuingOffice.municipal,
        ),
        DocumentRequest(
          trackingNumber: "TRK-100202",
          type: "Cedula",
          purpose: "General Requirement",
          dateSubmitted: DateTime.now(),
          status: RequestStatus.pending,
          issuingOffice: IssuingOffice.municipal,
          currentOffice: IssuingOffice.barangay,
        ),
      ]);
    }
    notifyListeners();
  }
}
