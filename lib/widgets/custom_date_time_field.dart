import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class CustomDateTimeField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? hint;
  final bool enabled;
  
  const CustomDateTimeField({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppConstants.captionStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding / 2),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled 
                    ? Colors.grey 
                    : Colors.grey.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              color: enabled ? null : Colors.grey.withOpacity(0.1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.defaultPadding,
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isNotEmpty ? value : (hint ?? ''),
                  style: AppConstants.bodyStyle.copyWith(
                    color: value.isNotEmpty 
                        ? Colors.black87 
                        : Colors.black54,
                  ),
                ),
                Icon(
                  icon,
                  color: enabled 
                      ? AppConstants.primaryColor 
                      : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 