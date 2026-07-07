import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

class AuthTextField extends StatefulWidget {
    final String hintText;
    final TextInputType keyboardType;
    final bool obscureText;
    final TextEditingController controller;
    final IconData? prefixIcon;
    final String? Function(String?)? validator;
    final void Function(String?)? onSaved;
    final TextInputAction? textInputAction;
    final void Function(String)? onFieldSubmitted;
    final List<TextInputFormatter>? inputFormatters;
    final FocusNode? focusNode;

    const AuthTextField({
        super.key,
        required this.hintText,
        required this.controller,
        this.keyboardType = TextInputType.text,
        this.obscureText = false,
        this.prefixIcon,
        this.validator,
        this.onSaved,
        this.textInputAction,
        this.onFieldSubmitted,
        this.inputFormatters,
        this.focusNode,
    });

    @override
    State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
    late bool _obscure;

    @override
    void initState() {
        super.initState();
        _obscure = widget.obscureText;
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: MediaQuery.of(context).size.width * 0.75,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                    ),
                ],
            ),
            child: TextFormField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                obscureText: _obscure,
                validator: widget.validator,
                onSaved: widget.onSaved,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onFieldSubmitted,
                inputFormatters: widget.inputFormatters,
                focusNode: widget.focusNode,
                style: const TextStyle(fontSize: 20, color: Color(0xFF0B0C0C)),
                decoration: InputDecoration(
                    hintText: widget.hintText,
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
                    ),
                    suffixIcon: widget.obscureText
                        ? IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textoPlaceholder,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          )
                        : null,
                ),
            ),
        );
    }
}
