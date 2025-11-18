import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/models/service_model.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ServiceCard extends StatelessWidget {
  final Service service;

  const ServiceCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB5BFAE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              image: service.serviceImage.isNotEmpty
                  ? DecorationImage(
                      image: MemoryImage(base64.decode(service.serviceImage)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: service.serviceImage.isEmpty
                ? const Icon(Icons.image, size: 50, color: Colors.grey)
                : null,
          ),

          // Service Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Postado por ${service.userCreator.name}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Chronos
                Row(
                  children: [
                    Image.asset('assets/img/Coin.png', width: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${service.timeChronos} chronos',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Categories
                if (service.categoryEntities.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: service.categoryEntities.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amareloClaro,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/img/Paintbrush.png', width: 16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
