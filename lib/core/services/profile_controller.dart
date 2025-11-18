import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileController {
  User? user;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> loadUserProfile() async {
    isLoading = true;
    try {
      final token = await _getToken();
      if (token == null) {
        errorMessage = "Token não encontrado";
        isLoading = false;
        return;
      }

      final response = await ApiService.get("/user/get/3", token: token);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        user = User.fromJson(userData);
        errorMessage = '';
      } else {
        errorMessage = "Erro ao carregar perfil";
      }
    } catch (e) {
      errorMessage = "Erro: $e";
    }
    isLoading = false;
  }

  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String phone,
    String? chronora,
    String? descricao,
    String? newPassword,
    String? currentPassword,
  }) async {
    isLoading = true;
    try {
      final token = await _getToken();
      if (token == null) {
        errorMessage = "Token não encontrado";
        isLoading = false;
        return false;
      }

      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        if (chronora != null && chronora.isNotEmpty) 'chronora': chronora,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
        if (currentPassword != null && currentPassword.isNotEmpty) 'currentPassword': currentPassword,
      };

      final response = await ApiService.patch(
        '/user/update',
        body,
        token: token,
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        user = User.fromJson(userData);
        errorMessage = '';
        isLoading = false;
        return true;
      } else {
        errorMessage = "Erro ao atualizar perfil";
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = "Erro: $e";
      isLoading = false;
      return false;
    }
  }

  Future<bool> deleteUserAccount() async {
    isLoading = true;
    try {
      final token = await _getToken();
      if (token == null) {
        errorMessage = "Token não encontrado";
        isLoading = false;
        return false;
      }

      final response = await ApiService.delete(
        '/user/delete',
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Limpar token após deletar conta
        await _clearToken();
        errorMessage = '';
        isLoading = false;
        return true;
      } else {
        errorMessage = "Erro ao deletar conta";
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = "Erro: $e";
      isLoading = false;
      return false;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
