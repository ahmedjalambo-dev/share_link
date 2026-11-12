import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// Edits one text setting. Returns the new value, or null if cancelled.
Future<String?> showTextSettingDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  required FormFieldValidator<String> validator,
  String Function(String value)? helper,
  int? maxLength,
  bool numeric = false,
  bool password = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextSettingDialog(
      title: title,
      initialValue: initialValue,
      validator: validator,
      helper: helper,
      maxLength: maxLength,
      numeric: numeric,
      password: password,
    ),
  );
}

class _TextSettingDialog extends StatefulWidget {
  const _TextSettingDialog({
    required this.title,
    required this.initialValue,
    required this.validator,
    required this.helper,
    required this.maxLength,
    required this.numeric,
    required this.password,
  });

  final String title;
  final String initialValue;
  final FormFieldValidator<String> validator;

  /// Helper text built from the current input (e.g. the full network name).
  final String Function(String value)? helper;
  final int? maxLength;
  final bool numeric;

  /// Adds show/hide and "generate" buttons.
  final bool password;

  @override
  State<_TextSettingDialog> createState() => _TextSettingDialogState();
}

class _TextSettingDialogState extends State<_TextSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);
  late bool _obscure = widget.password;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final random = Random.secure();
    _controller.text = List.generate(
      10,
      (_) => kPasswordChars[random.nextInt(kPasswordChars.length)],
    ).join();
    setState(() => _obscure = false);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          obscureText: _obscure,
          maxLength: widget.maxLength,
          textDirection: TextDirection.ltr,
          keyboardType: widget.numeric ? TextInputType.number : null,
          inputFormatters: widget.numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            helperText: widget.helper?.call(_controller.text),
            helperMaxLines: 2,
            errorMaxLines: 3,
            suffixIcon: widget.password
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        tooltip: _obscure ? l.showPassword : l.hidePassword,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      IconButton(
                        icon: const Icon(Icons.autorenew),
                        tooltip: l.generatePassword,
                        onPressed: _generatePassword,
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}

/// Picks one of [options] (value → label). Returns the choice, or null if dismissed.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  required T selected,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        RadioGroup<T>(
          groupValue: selected,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final MapEntry(key: value, value: label) in options.entries)
                RadioListTile<T>(value: value, title: Text(label)),
            ],
          ),
        ),
      ],
    ),
  );
}
