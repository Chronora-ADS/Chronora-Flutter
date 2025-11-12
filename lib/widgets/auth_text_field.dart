import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AuthTextField extends StatelessWidget {
    final String hintText;
    final TextInputType keyboardType;
    final bool obscureText;
    final TextEditingController controller;
    final IconData? prefixIcon;
    final String? Function(String?)? validator;
    final void Function(String?)? onSaved;

    const AuthTextField({
        super.key,
        required this.hintText,
        required this.controller,
        this.keyboardType = TextInputType.text,
        this.obscureText = false,
        this.prefixIcon,
        this.validator,
        this.onSaved,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            width: MediaQuery.of(context).size.width * 0.75,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                    ),
                ],
            ),
            child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                validator: validator,
                onSaved: onSaved,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.brancoBorda, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.brancoBorda, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    )
                ),
            ),
        );
    }
}