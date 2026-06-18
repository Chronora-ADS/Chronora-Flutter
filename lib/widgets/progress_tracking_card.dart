import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/models/service_tracking_type.dart';

class ProgressTrackingCard extends StatelessWidget {
  final ServiceTrackingType trackingType;
  final String? trackingDescription;

  const ProgressTrackingCard({
    super.key,
    required this.trackingType,
    this.trackingDescription,
  });

  @override
  Widget build(BuildContext context) {
    final customDescription = trackingDescription?.trim();
    final detail = trackingType == ServiceTrackingType.custom &&
            customDescription != null &&
            customDescription.isNotEmpty
        ? customDescription
        : trackingType.explanation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloUmPoucoEscuro, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.amareloClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.track_changes,
              color: AppColors.preto,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Métrica de Progresso',
                  style: TextStyle(
                    color: AppColors.preto,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trackingType.label,
                  style: const TextStyle(
                    color: AppColors.amareloUmPoucoEscuro,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textoPlaceholder,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
