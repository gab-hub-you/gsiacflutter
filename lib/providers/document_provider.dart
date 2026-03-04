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
      attachmentPath: attachmentPath,
    );

    _requests.insert(0, newRequest);
    _isLoading = false;
    notifyListeners();
    return trackingNumber;
  }

  Future<void> fetchRequests() async {
    // Mock fetching from API
    if (_requests.isEmpty) {
      _requests.addAll([
        DocumentRequest(
          trackingNumber: "TRK-100200",
          type: "Barangay Clearance",
          purpose: "Employment",
          dateSubmitted: DateTime.now().subtract(const Duration(days: 2)),
          status: RequestStatus.approved,
        ),
        DocumentRequest(
          trackingNumber: "TRK-100201",
          type: "Certificate of Residency",
          purpose: "ID Application",
          dateSubmitted: DateTime.now().subtract(const Duration(days: 1)),
          status: RequestStatus.underReview,
        ),
      ]);
    }
    notifyListeners();
  }
}
