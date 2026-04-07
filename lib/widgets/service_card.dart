import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/main_page_requests_model.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onView;
  final Function(bool) onCardEdited;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onView,
    required this.onCardEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          print('=== SERVICE CARD TAPPED ===');
          print('Chamando onView para serviço ID: ${service.id}');
          onView();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/img/CoinYellow.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.timeChronos}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amareloClaro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                service.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.cinza,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: service.categoryEntities.map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amareloClaro.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.amareloClaro,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amareloUmPoucoEscuro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service.modality,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.branco,
                      ),
                    ),
                  ),
                  Text(
                    'Prazo: ${_formatDate(service.deadline)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinza,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}