import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final bool isRequired;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.hint,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        hint: hint != null ? Text(hint!) : null,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired
            ? (value) => value == null || value.isEmpty
                ? 'Please select $label'
                : null
            : null,
      ),
    );
  }
}
