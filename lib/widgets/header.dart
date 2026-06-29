import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_service.dart';
import '../../core/services/auth_session_service.dart';
import 'wallet_modal.dart';

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
      final String? token = await AuthSessionService.getValidAccessToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _coinCount = 0;
        });
        return;
      }

      final response = await ApiService.get('/user/get', token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _coinCount = (jsonData is Map ? jsonData['timeChronos'] : null) ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _coinCount = 0;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _coinCount = 0;
      });
    }
  }

  void _openWallet() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: WalletModal(onClose: () => Navigator.of(context).pop()),
      ),
    );
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
        GestureDetector(
          onTap: _openWallet,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
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
              ],
            ),
          ),
        ),
      ],
      elevation: 0,
    );
  }
}
