import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../models/prediction_model.dart';

class PredictionCard extends StatelessWidget {
  final PredictionModel prediction;
  final VoidCallback? onTap;
  
  const PredictionCard({
    Key? key,
    required this.prediction,
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
                    'Prediction for ${Formatters.formatDate(prediction.date)}',
                    style: AppConstants.subheadingStyle,
                  ),
                  _buildRiskIndicator(prediction.predictionScore),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              const Divider(),
              const SizedBox(height: AppConstants.smallPadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    icon: Icons.warning_amber_rounded,
                    value: Formatters.formatPredictionScore(prediction.predictionScore),
                    label: 'Risk Score',
                  ),
                  _buildStat(
                    icon: Icons.nights_stay,
                    value: prediction.predictedInterruptionCount.toString(),
                    label: 'Interruptions',
                  ),
                  _buildStat(
                    icon: Icons.electric_bolt,
                    value: '${prediction.contributingFactors.length}',
                    label: 'Factors',
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              const Text(
                'Predicted Interruption Windows:',
                style: AppConstants.captionStyle,
              ),
              const SizedBox(height: AppConstants.smallPadding / 2),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: prediction.predictedInterruptionWindows.length,
                  itemBuilder: (context, index) {
                    final window = prediction.predictedInterruptionWindows[index];
                    return _buildInterruptionWindow(window);
                  },
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              const Divider(),
              const SizedBox(height: AppConstants.smallPadding / 2),
              const Text(
                'Top Recommendations:',
                style: AppConstants.captionStyle,
              ),
              const SizedBox(height: AppConstants.smallPadding / 2),
              Column(
                children: prediction.recommendations
                    .take(2)
                    .map((recommendation) => _buildRecommendation(recommendation))
                    .toList(),
              ),
              if (prediction.recommendations.length > 2) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${prediction.recommendations.length - 2} more recommendations',
                  style: AppConstants.captionStyle.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRiskIndicator(double risk) {
    Color color;
    if (risk < 0.2) {
      color = Colors.green;
    } else if (risk < 0.4) {
      color = Colors.lime;
    } else if (risk < 0.6) {
      color = Colors.amber;
    } else if (risk < 0.8) {
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
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            Formatters.formatPredictionRisk(risk),
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
  
  Widget _buildInterruptionWindow(Map<String, dynamic> window) {
    final startTime = window['startTime'] as DateTime;
    final endTime = window['endTime'] as DateTime;
    final probability = window['probability'] as double;
    
    Color color;
    if (probability < 0.7) {
      color = Colors.amber;
    } else if (probability < 0.85) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.smallPadding),
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${Formatters.formatTime(startTime)} - ${Formatters.formatTime(endTime)}',
            style: AppConstants.captionStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${(probability * 100).round()}% chance',
            style: AppConstants.captionStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendation(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppConstants.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: AppConstants.captionStyle,
            ),
          ),
        ],
      ),
    );
  }
} 