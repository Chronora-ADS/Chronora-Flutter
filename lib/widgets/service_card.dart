import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:flutter/material.dart';
import 'package:chronora/widgets/service_image.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final ValueChanged<bool>? onCardEdited;
  final bool enableNavigation;
  final String? navigationRoute;
  final Object? navigationArguments;

  const ServiceCard({
    super.key,
    required this.service,
    this.onEdit,
    this.onView,
    this.onCardEdited,
    this.enableNavigation = true,
    this.navigationRoute,
    this.navigationArguments,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (onView != null) {
      onView!();
      return;
    }

    if (!enableNavigation) {
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      navigationRoute ?? '${AppRoutes.requestView}/${service.id}',
      arguments: navigationArguments ?? service,
    );

    if (result == true && onCardEdited != null) {
      onCardEdited!(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          enableNavigation || onView != null ? () => _handleTap(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB5BFAE),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: service.serviceImageUrl.isNotEmpty
                      ? ServiceImage(
                          imageSource: service.serviceImageUrl,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.black45,
                          ),
                        ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amareloUmPoucoEscuro,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(service.deadline),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.branco,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amareloUmPoucoEscuro,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.modality,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.branco,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                          iconSize: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Postado por ${service.userCreator.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset('assets/img/Coin.png', width: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${service.timeChronos} chronos',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (service.categoryEntities.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.categoryEntities.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amareloClaro,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/img/Paintbrush.png',
                                width: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
