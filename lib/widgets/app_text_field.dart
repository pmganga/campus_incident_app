import 'package:flutter/material.dart';

/// A labelled form field with an optional icon. Password fields get a
/// show/hide toggle; set [maxLines] above 1 for multi-line text.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hintText;
  final String? helperText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hintText,
    this.helperText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.maxLines > 1 ? TextInputAction.newline : widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      obscureText: widget.isPassword && _obscured,
      autocorrect: !widget.isPassword,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.maxLines > 1 ? 3 : null,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
