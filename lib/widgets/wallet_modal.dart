import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class WalletModal extends StatefulWidget {
  final VoidCallback onClose;

  const WalletModal({super.key, required this.onClose});

  @override
  State<WalletModal> createState() => _WalletModalState();
}

class _WalletModalState extends State<WalletModal> {
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
      final jsonData = json.decode(responseBody);
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              const Center(
                child: Text(
                  'Carteira',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.preto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const ImageIcon(
                    AssetImage('assets/img/Close.png'),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.preto),
                        ),
                      )
                    : Text(
                        _coinCount.toString(), // Usa o valor buscado localmente
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.preto,
                        ),
                      ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/img/Coin.png',
                  width: 32,
                  height: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.amareloUmPoucoEscuro,
            ),
            child: InkWell(
              onTap: () {
                widget.onClose();
                Navigator.pushNamed(context, '/buy-chronos');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Comprar Chronos',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.branco,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.branco,
              border: Border.all(
                color: AppColors.amareloUmPoucoEscuro,
                width: 4,
              ),
            ),
            child: InkWell(
              onTap: () {
                widget.onClose();
                Navigator.pushNamed(context, '/sell-chronos');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Vender Chronos',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.amareloUmPoucoEscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}