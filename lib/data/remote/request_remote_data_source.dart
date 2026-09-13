import '../../models/request.dart';
import '../../services/request_service.dart';

class RequestRemoteDataSource {
  RequestRemoteDataSource([RequestService? service])
    : _service = service ?? RequestService();
  final RequestService _service;
  RequestService get _delegate => _service;
  Future<CreatedRequest> createRequest(int donationId) =>
      _delegate.createRequest(donationId);
  Future<RequestPage<SentRequestListItem>> getSentRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) => _delegate.getSentRequests(page: page, limit: limit, status: status);
  Future<RequestPage<ReceivedRequestListItem>> getReceivedRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) => _delegate.getReceivedRequests(page: page, limit: limit, status: status);
  Future<RequestDetail> getRequestById(int id) => _delegate.getRequestById(id);
  Future<RequestDetail> acceptRequest(int id) => _delegate.acceptRequest(id);
  Future<RequestDetail> rejectRequest(int id) => _delegate.rejectRequest(id);
  Future<RequestDetail> cancelRequest(int id) => _delegate.cancelRequest(id);
}
