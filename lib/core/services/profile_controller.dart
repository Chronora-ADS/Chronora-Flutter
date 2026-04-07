import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileController {
  User? user;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> loadUserProfile() async {
    isLoading = true;
    errorMessage = '';

    try {
      final token = await _getToken();
      if (token == null) {
        errorMessage = 'Token nÃ£o encontrado';
        isLoading = false;
        return;
      }

      if (kDebugMode) {
        debugPrint('[ProfileController] Carregando perfil do usuÃ¡rio...');
      }

      final response = await ApiService.get('/user/get', token: token);

      if (kDebugMode) {
        debugPrint('[ProfileController] Status: ${response.statusCode}');
        debugPrint('[ProfileController] Resposta: ${response.body}');
      }

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        user = User.fromJson(_extractUserMap(userData));
        errorMessage = '';
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      errorMessage = 'Erro ao carregar perfil: $e';
      if (kDebugMode) {
        debugPrint('[ProfileController] Erro: $e');
      }
    }

    isLoading = false;
  }

  Future<bool> updateUserProfile({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    Map<String, String>? document,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = '';

    try {
      final token = await _getToken();
      if (token == null) {
        errorMessage = 'Token nÃ£o encontrado';
        isLoading = false;
        return false;
      }

      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        errorMessage = 'ID do usuÃ¡rio invÃ¡lido';
        isLoading = false;
        return false;
      }

      final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final parsedPhoneNumber = int.tryParse(normalizedPhoneNumber);
      if (parsedPhoneNumber == null) {
        errorMessage = 'Telefone invÃ¡lido';
        isLoading = false;
        return false;
      }

      final body = {
        'id': parsedId,
        'name': name,
        'email': email,
        'phoneNumber': parsedPhoneNumber,
        if (document != null) 'document': document,
        if (password != null && password.isNotEmpty) 'password': password,
      };

      if (kDebugMode) {
        debugPrint('[ProfileController] Atualizando perfil: $body');
      }

      final response = await ApiService.put('/user/put', body, token: token);

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        user = User.fromJson(_extractUserMap(userData));
        errorMessage = '';
        return true;
      }

      _handleErrorResponse(response);
      return false;
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
      final token = await _getToken();
      if (token == null) {
        errorMessage = 'Token nÃ£o encontrado';
        isLoading = false;
        return false;
      }

      final response = await ApiService.delete('/user/delete', token: token);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        user = null;
        errorMessage = '';
        return true;
      }

      _handleErrorResponse(response);
      return false;
    } catch (e) {
      errorMessage = 'Erro ao deletar conta: $e';
      return false;
    } finally {
      isLoading = false;
    }
  }

  void _handleErrorResponse(dynamic response) {
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['message'] ?? 'Erro: ${response.statusCode}';
    } catch (_) {
      errorMessage = 'Erro: ${response.statusCode}';
    }
  }

  Map<String, dynamic> _extractUserMap(dynamic userData) {
    if (userData is Map && userData.containsKey('data')) {
      return (userData['data'] as Map).cast<String, dynamic>();
    }

    if (userData is Map && userData.containsKey('user')) {
      return (userData['user'] as Map).cast<String, dynamic>();
    }

    if (userData is Map) {
      return userData.cast<String, dynamic>();
    }

    throw const FormatException('Formato de resposta invÃ¡lido');
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileController] Erro ao obter token: $e');
      }
      return null;
    }
  }
}
