import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pocket_ledger/core/api/backend_client.dart';

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, String?>((ref) {
  return WorkspaceNotifier();
});

class WorkspaceNotifier extends StateNotifier<String?> {
  WorkspaceNotifier() : super(null);

  void setActiveWorkspace(String companyId) {
    state = companyId;
    backendClient.activeCompanyId = companyId;
  }
}

// In a real app, you'd fetch the user's available companies from the backend
final userCompaniesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await backendClient.get('/api/companies');
    if (response != null && response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
  } catch (e) {
    // Ignore errors for now or handle them
  }
  return [];
});
