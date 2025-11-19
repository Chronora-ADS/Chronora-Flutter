// controllers/profile_controller.dart
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
        errorMessage = "Token não encontrado";
        isLoading = false;
        return;
      }
      
      if (kDebugMode) {
        debugPrint('[ProfileController] Carregando perfil do usuário...');
      }

      final response = await ApiService.get("/user/get", token: token);
      
      if (kDebugMode) {
        debugPrint('[ProfileController] Status: ${response.statusCode}');
        debugPrint('[ProfileController] Resposta: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Debug para ver a estrutura da resposta
        if (kDebugMode) {
          debugPrint('[ProfileController] Estrutura da resposta: ${userData.runtimeType}');
          if (userData is Map) {
            debugPrint('[ProfileController] Chaves: ${userData.keys}');
          }
        }
        
        // Tenta diferentes estruturas de resposta
        Map<String, dynamic> parsedData;
        
        if (userData is Map && userData.containsKey('data')) {
          parsedData = userData['data'] as Map<String, dynamic>;
        } else if (userData is Map && userData.containsKey('user')) {
          parsedData = userData['user'] as Map<String, dynamic>;
        } else if (userData is Map) {
          parsedData = userData.cast<String, dynamic>();
        } else {
          throw FormatException('Formato de resposta inválido');
        }
        
        user = User.fromJson(parsedData);
        errorMessage = '';
        
        if (kDebugMode) {
          debugPrint('[ProfileController] Perfil carregado com sucesso: ${user!.name}');
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      errorMessage = "Erro ao carregar perfil: $e";
      if (kDebugMode) {
        debugPrint('[ProfileController] Erro: $e');
      }
    }
    isLoading = false;
  }

  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String phoneNumber,
    String? newPassword,
    String? currentPassword,
  }) async {
    isLoading = true;
    errorMessage = '';
    
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
        'phoneNumber': phoneNumber,
        if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
        if (currentPassword != null && currentPassword.isNotEmpty) 'currentPassword': currentPassword,
      };

      if (kDebugMode) {
        debugPrint('[ProfileController] Atualizando perfil: $body');
      }

      final response = await ApiService.patch(
        '/user/update',
        body,
        token: token,
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        user = User.fromJson(userData);
        errorMessage = '';
        return true;
      } else {
        _handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      errorMessage = "Erro ao atualizar perfil: $e";
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
        errorMessage = "Token não encontrado";
        isLoading = false;
        return false;
      }

      final response = await ApiService.delete(
        '/user/delete',
        token: token,
      );

      if (response.statusCode == 200) {
        // Limpar token e dados do usuário
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        
        user = null;
        errorMessage = '';
        return true;
      } else {
        _handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      errorMessage = "Erro ao deletar conta: $e";
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