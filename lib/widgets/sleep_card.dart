import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../models/sleep_data_model.dart';

class SleepCard extends StatelessWidget {
  final SleepDataModel sleepData;
  final VoidCallback? onTap;
  
  const SleepCard({
    Key? key,
    required this.sleepData,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDate(sleepData.date),
                    style: AppConstants.subheadingStyle,
                  ),
                  _buildQualityIndicator(sleepData.sleepQuality),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatTime(sleepData.bedTime),
                    style: AppConstants.captionStyle,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.alarm_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatTime(sleepData.wakeUpTime),
                    style: AppConstants.captionStyle,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              const Divider(),
              const SizedBox(height: AppConstants.smallPadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    icon: Icons.access_time,
                    value: Formatters.formatDuration(sleepData.sleepDuration),
                    label: 'Duration',
                  ),
                  _buildStat(
                    icon: Icons.snooze,
                    value: '${sleepData.timeToFallAsleep}m',
                    label: 'Fall Asleep',
                  ),
                  _buildStat(
                    icon: Icons.nights_stay,
                    value: sleepData.interruptionCount.toString(),
                    label: 'Interruptions',
                  ),
                ],
              ),
              if (sleepData.notes.isNotEmpty) ...[
                const SizedBox(height: AppConstants.smallPadding),
                const Divider(),
                const SizedBox(height: AppConstants.smallPadding / 2),
                Text(
                  'Notes:',
                  style: AppConstants.captionStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  sleepData.notes,
                  style: AppConstants.captionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQualityIndicator(double quality) {
    Color color;
    if (quality >= 8) {
      color = Colors.green;
    } else if (quality >= 6) {
      color = Colors.lime;
    } else if (quality >= 4) {
      color = Colors.amber;
    } else if (quality >= 2) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            Formatters.formatSleepQuality(quality),
            style: AppConstants.captionStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppConstants.primaryColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppConstants.captionStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
} 