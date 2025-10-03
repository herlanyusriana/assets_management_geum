import "api_client.dart";

class UserApiService {
  UserApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<dynamic>> fetchUsers() async {
    final response = await _client.get<Map<String, dynamic>>('/users');
    final data = response.data;
    if (data == null) {
      return const [];
    }
    final users = data['data'];
    if (users is List) {
      return users;
    }
    return const [];
  }
}
