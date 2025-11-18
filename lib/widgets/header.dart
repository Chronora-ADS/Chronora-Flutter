import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const Header({
    super.key,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  int _coinCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final String? token = await _getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _coinCount = 0;
        });
        return;
      }

      final response = await ApiService.get('/user/get', token: token);

      if (response.statusCode == 200) {
        final userData = _parseResponse(response.body);
        setState(() {
          _coinCount = userData['timeChronos'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _coinCount = 0;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _coinCount = 0;
      });
    }
  }

  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      // Tenta fazer parse como JSON primeiro
      final jsonData = json.decode(responseBody);

      // Verifica se é um objeto UserEntity completo
      if (jsonData is Map<String, dynamic>) {
        final chronos = jsonData['timeChronos'] ?? 0;
        return {'timeChronos': chronos};
      }
      return {'timeChronos': 0};
    } catch (e) {
      return {'timeChronos': 0};
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.amareloClaro,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.preto),
        onPressed: widget.onMenuPressed,
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/img/LogoHeader.png',
            width: 125,
            height: 32,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Image.asset('assets/img/Coin.png', width: 24, height: 24),
            const SizedBox(width: 4),
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.preto),
                    ),
                  )
                : Text(
                    _coinCount.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                  ),
            const SizedBox(width: 16),
          ],
        ),
      ],
      elevation: 0,
    );
  }
}
