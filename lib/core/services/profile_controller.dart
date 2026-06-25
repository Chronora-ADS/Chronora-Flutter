import 'dart:convert';

import '../api/api_service.dart';
import '../models/user_model.dart';
import 'auth_session_service.dart';

class ProfileController {
  User? user;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> loadUserProfile() async {
    isLoading = true;
    errorMessage = '';

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        errorMessage = 'Usuário não autenticado.';
        return;
      }

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) {
        errorMessage = ApiService.extractErrorMessage(
          response.body,
          fallback: 'Não foi possível carregar o perfil.',
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      user = User.fromJson(_extractUserMap(decoded));
    } catch (e) {
      errorMessage = 'Erro ao carregar perfil: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateUserProfile({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    Map<String, String>? document,
    Map<String, String>? profileImage,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = '';

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        errorMessage = 'Usuário não autenticado.';
        return false;
      }

      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        errorMessage = 'ID do usuário inválido.';
        return false;
      }

      final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final parsedPhoneNumber = normalizedPhoneNumber.isEmpty
          ? null
          : int.tryParse(normalizedPhoneNumber);

      final body = <String, dynamic>{
        'id': parsedId,
        'name': name.trim(),
        'email': email.trim(),
        if (parsedPhoneNumber != null) 'phoneNumber': parsedPhoneNumber,
        if (document != null) 'document': document,
        if (profileImage != null) 'profileImage': profileImage,
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
      };

      final response = await ApiService.put('/user/put', body, token: token);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await AuthSessionService.clearSession();
        }
        errorMessage = ApiService.extractErrorMessage(
          response.body,
          fallback: 'Não foi possível atualizar o perfil.',
        );
        return false;
      }

      final trimmedBody = response.body.trim();
      if (trimmedBody.isNotEmpty) {
        final decoded = jsonDecode(trimmedBody);
        user = User.fromJson(_extractUserMap(decoded));
      } else {
        await loadUserProfile();
      }

      return true;
    } catch (e) {
      errorMessage = 'Erro ao atualizar perfil: $e';
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    errorMessage = '';

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        errorMessage = 'Usuário não autenticado.';
        return false;
      }

      final response = await ApiService.delete('/user/delete', token: token);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await AuthSessionService.clearSession();
        user = null;
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthSessionService.clearSession();
      }

      errorMessage = ApiService.extractErrorMessage(
        response.body,
        fallback: 'Não foi possível deletar a conta.',
      );
      return false;
    } catch (e) {
      errorMessage = 'Erro ao deletar conta: $e';
      return false;
    } finally {
      isLoading = false;
    }
  }

  Map<String, dynamic> _extractUserMap(dynamic userData) {
    if (userData is Map<String, dynamic>) {
      if (userData['data'] is Map<String, dynamic>) {
        return userData['data'] as Map<String, dynamic>;
      }
      if (userData['user'] is Map<String, dynamic>) {
        return userData['user'] as Map<String, dynamic>;
      }
      return userData;
    }

    throw const FormatException('Formato de resposta inválido.');
  }
}
