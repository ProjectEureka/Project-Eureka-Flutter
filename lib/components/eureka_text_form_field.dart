import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// This is a custom made TextForm made specifically for Project
/// Eureka. Please use this Widget when using any text form fields.
class EurekaTextFormField extends StatefulWidget {
  final String labelText;
  final TextCapitalization textCapitalization;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final String errValidatorMsg;
  final RegExp regExp;
  final Function onSaved;
  final String initialValue;
  final bool obscureText;
  final bool customValidator;
  final String validatorCheck;
  final String regexValidatorMessage;
  final String customValidatorMessage;

  /// labelText, errValidatorMsg, validator RegEx, and onSaved functions are
  /// all required. textCapitalization, keyboardType, textInputAction, and
  /// maxLines are all option and if they have no values passed in, they
  /// will use the default values found below.
  EurekaTextFormField(
      {@required this.labelText,
      this.textCapitalization,
      this.keyboardType,
      this.textInputAction,
      this.maxLines,
      @required this.errValidatorMsg,
      this.regExp,
      @required this.onSaved,
      this.initialValue,
      this.obscureText,
      this.customValidator,
      this.validatorCheck,
      this.regexValidatorMessage,
      this.customValidatorMessage});

  @override
  _EurekaTextFormFieldState createState() => _EurekaTextFormFieldState();
}

/// This widget will always add spacing of 20.0 below the text form
class _EurekaTextFormFieldState extends State<EurekaTextFormField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          /// if param added, else default value
          textCapitalization: widget.textCapitalization == null
              ? TextCapitalization.sentences
              : widget.textCapitalization,
          keyboardType: widget.keyboardType == null
              ? TextInputType.text
              : widget.keyboardType,
          textInputAction: widget.textInputAction == null
              ? TextInputAction.next
              : widget.textInputAction,
          maxLines: widget.maxLines == null ? 1 : widget.maxLines,
          validator: (value) {
            if (value.isEmpty) {
              return widget.errValidatorMsg;
            } else if (!widget.regExp.hasMatch(value)) {
              return widget.regexValidatorMessage == null
                  ? 'Invalid input.'
                  : widget.regexValidatorMessage;
            } else if (widget.customValidator == null
                ? false
                : (value != widget.validatorCheck)) {
              return widget.customValidatorMessage;
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: widget.labelText,
          ),
          onSaved: widget.onSaved,
          initialValue:
              widget.initialValue == null ? null : widget.initialValue,
          obscureText: widget.obscureText == null ? false : widget.obscureText,
        ),
        SizedBox(
          height: 20.0,
        )
      ],
    );
  }
}
