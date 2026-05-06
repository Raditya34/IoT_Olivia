import '../storage/auth_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<void> login(String email, String password) async {
    final data = await _api
        .postPublic('/auth/login', {'email': email, 'password': password});

    final token = data['token'] as String?;
    if (token != null) {
      await AuthStorage.saveToken(token);
    }
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _api.postPublic(
        '/auth/register', {'name': name, 'email': email, 'password': password});

    final token = data['token'] as String?;
    if (token != null) {
      await AuthStorage.saveToken(token);
    }
  }
}
