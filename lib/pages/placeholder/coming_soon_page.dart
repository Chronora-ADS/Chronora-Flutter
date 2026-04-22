import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  final String description;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      appBar: AppBar(
        backgroundColor: AppColors.amareloClaro,
        foregroundColor: AppColors.preto,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 48,
                  color: AppColors.amareloUmPoucoEscuro,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      foregroundColor: AppColors.branco,
                    ),
                    child: const Text('Voltar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
