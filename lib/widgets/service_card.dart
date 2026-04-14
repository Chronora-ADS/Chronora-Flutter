import 'dart:convert';

import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:flutter/material.dart';

import '../core/api/api_service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onCardEdited;

  const ServiceCard({
    super.key,
    required this.service,
    this.onEdit,
    this.onCardEdited,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/request-editing',
          arguments: service,
        );

        if (result == true && onCardEdited != null) {
          onCardEdited!(true);
        }
      },
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
                _buildServiceImage(),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                              Image.asset('assets/img/Paintbrush.png',
                                  width: 16),
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

  Widget _buildServiceImage() {
    final imageValue = _normalizeImageValue(service.serviceImage);

    if (imageValue.isEmpty) {
      return _buildImagePlaceholder();
    }

    if (_isDataUriImage(imageValue)) {
      return _buildBase64Image(imageValue.split(',').last);
    }

    if (_isNetworkImage(imageValue)) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Image.network(
          imageValue,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
      );
    }

    if (_isLikelyBase64(imageValue)) {
      return _buildBase64Image(imageValue);
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFD8DBD2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool _isDataUriImage(String value) {
    return value.startsWith('data:image/');
  }

  bool _isLikelyBase64(String value) {
    final normalized = value.replaceAll('\n', '').trim();
    if (normalized.length < 80 || normalized.contains(' ')) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(normalized);
  }

  Widget _buildBase64Image(String value) {
    try {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Image.memory(
          base64.decode(value),
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
      );
    } catch (_) {
      return _buildImagePlaceholder();
    }
  }

  String _normalizeImageValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (_isDataUriImage(trimmed) || _isLikelyBase64(trimmed)) {
      return trimmed;
    }

    final imageUri = Uri.tryParse(trimmed);
    if (imageUri == null) {
      return trimmed;
    }

    if (!imageUri.hasScheme) {
      return Uri.parse(ApiService.baseUrl).resolveUri(imageUri).toString();
    }

    if (_isLocalhostUri(imageUri)) {
      final apiBaseUri = Uri.parse(ApiService.baseUrl);
      return imageUri
          .replace(
            scheme: apiBaseUri.scheme,
            host: apiBaseUri.host,
            port: apiBaseUri.hasPort ? apiBaseUri.port : null,
          )
          .toString();
    }

    return trimmed;
  }

  bool _isLocalhostUri(Uri uri) {
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }
}
