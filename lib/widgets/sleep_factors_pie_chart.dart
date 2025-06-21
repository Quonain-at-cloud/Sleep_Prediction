import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Data class to hold processed chart data
class PieData {
  final String name;
  final double percent;
  final Color color;
  final bool isExploded;
  final String originalValueDisplay; // For labels like "High Temperature (40)"

  PieData({
    required this.name,
    required this.percent,
    required this.color,
    this.isExploded = false,
    required this.originalValueDisplay,
  });
}

class SleepFactorsPieChart extends StatefulWidget {
  final Map<String, dynamic> contributingFactors; // Values are impact scores (0.0-1.0)
  final String? chartTitle; // Optional title like "Factors contributing to sleep loss (noise level 80db)"

  const SleepFactorsPieChart({
    Key? key,
    required this.contributingFactors,
    this.chartTitle,
  }) : super(key: key);

  @override
  State<SleepFactorsPieChart> createState() => _SleepFactorsPieChartState();
}

class _SleepFactorsPieChartState extends State<SleepFactorsPieChart> {
  List<PieData> chartData = [];
  int touchedIndex = -1;

  // Define colors based on the screenshot - order matters if factors are consistent
  final List<Color> _sliceColors = [
    const Color(0xFFD1C4E9), // Light Purple (for the largest slice, e.g., Noise Level)
    const Color(0xFFFFAB91), // Light Orange (e.g., High Temperature)
    const Color(0xFFB9F6CA), // Light Green (e.g., Dietary Variety)
    const Color(0xFF81D4FA), // Light Blue (e.g., Device Use)
    const Color(0xFFFFCDD2), // Light Red (e.g., Midnight Awakenings - exploded)
  ];

  // Define the order of factors as they appear in the screenshot (clockwise from top)
  // This helps in assigning colors correctly and exploding the right slice.
  // This order should ideally match the order of factors in your screenshot.
  final List<String> _factorOrder = [
    // This is an assumption based on typical pie chart rendering.
    // Adjust if your ML service returns factors in a different dominant order or if colors are tied to specific factor names.
    'Noise Level', // Or whatever the top-most, largest purple slice represents
    'High Temperature',
    'Dietary Variety',
    'Device Use',
    'Midnight Awakenings',
  ];


  @override
  void initState() {
    super.initState();
    _prepareChartData();
  }

  @override
  void didUpdateWidget(covariant SleepFactorsPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contributingFactors != oldWidget.contributingFactors) {
      _prepareChartData();
    }
  }

  void _prepareChartData() {
    if (widget.contributingFactors.isEmpty) {
      setState(() {
        chartData = [];
      });
      return;
    }

    // Convert impact scores to percentages
    final double totalImpact = widget.contributingFactors.values
        .map((dynamic value) => (value is int ? value.toDouble() : value as double))
        .where((value) => value > 0) // Consider only positive impact scores for total
        .fold(0.0, (sum, item) => sum + item);


    if (totalImpact == 0) {
       setState(() {
        chartData = [];
      });
      return;
    }
    
    List<PieData> unsortedData = [];
    widget.contributingFactors.forEach((key, dynamic value) {
      double factorValue = (value is int ? value.toDouble() : value as double);
      if (factorValue <= 0) return; // Skip factors with no or negative impact for display

      double percent = (factorValue / totalImpact) * 100;
      
      String originalValueDisplay = key;
      if (key == 'Device Use') {
        originalValueDisplay = "Device Use\n(blue light exposure)";
      } else if (key == 'High Temperature') {
        // TODO: Get the actual temperature value (e.g., 40) from widget.contributingFactors if available
        // For example, if it's passed as 'High Temperature_value': 40 or similar.
        // String tempValue = widget.contributingFactors['High Temperature_actual_value']?.toString() ?? "40"; 
        originalValueDisplay = "High Temperature\n(40)"; // Using placeholder from screenshot
      } else if (key == 'Midnight Awakenings') {
        originalValueDisplay = "Midnight\nAwakenings";
      } else if (key == 'Dietary Variety') {
        originalValueDisplay = "Dietary Variety"; // Corrected to single line as per screenshot
      }
      // 'Noise Level' will use its key directly if not matched above, assuming it's single line.


      unsortedData.add(PieData(
        name: key,
        percent: percent,
        color: Colors.grey, // Placeholder, will be assigned based on order
        isExploded: key == 'Midnight Awakenings',
        originalValueDisplay: originalValueDisplay,
      ));
    });

    // Sort data according to _factorOrder to ensure consistent coloring and explosion
    List<PieData> sortedData = [];
    for (String factorName in _factorOrder) {
      final dataIndex = unsortedData.indexWhere((d) => d.name == factorName);
      if (dataIndex != -1) {
        sortedData.add(unsortedData.removeAt(dataIndex));
      }
    }
    // Add any remaining data that wasn't in _factorOrder (in case of new/unexpected factors)
    sortedData.addAll(unsortedData);

    // Assign colors
    chartData = sortedData.asMap().entries.map((entry) {
      int idx = entry.key;
      PieData data = entry.value;
      return PieData(
        name: data.name,
        percent: data.percent,
        color: _sliceColors[idx % _sliceColors.length], // Cycle through colors
        isExploded: data.isExploded,
        originalValueDisplay: data.originalValueDisplay,
      );
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(child: Text('No contributing factors data to display.'));
    }

    return Column(
      children: [
        if (widget.chartTitle != null && widget.chartTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 80.0, left: 0, right: 0),
            child: Text(
              widget.chartTitle!,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87), 
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
                          // Determine the largest square that can fit within the available constraints.
              final double actualSquareSize = math.min(constraints.maxWidth, constraints.maxHeight);
              
              // Calculate the pie radius based on this square size and user's preference (0.65 factor).
              final double pieRadiusForSections = actualSquareSize * 0.65;

              // Define the center of our square drawing canvas.
              final Offset canvasCenter = Offset(actualSquareSize / 2, actualSquareSize / 2);

              // Center the square canvas within the LayoutBuilder's potentially rectangular space.
              return Center(
                child: SizedBox(
                  width: actualSquareSize,
                  height: actualSquareSize,
                  child: Stack(
                    children: [ // Start of Stack's children list
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2.5,
                          centerSpaceRadius: pieRadiusForSections * 0.1,
                          sections: chartData.asMap().entries.map<PieChartSectionData>((entry) {
                            int idx = entry.key;
                            PieData data = entry.value;
                            final bool isTouched = idx == touchedIndex;
                            final double sectionActualRadius = data.isExploded
                                ? pieRadiusForSections * 1.1 
                                : (isTouched ? pieRadiusForSections * 1.05 : pieRadiusForSections);
                            final double titleFontSize = isTouched ? 10 : 9; // Slightly smaller for two lines 
                            final Color sectionColor = isTouched ? data.color.darken(0.1) : data.color;

                            return PieChartSectionData(
                              color: sectionColor,
                              value: data.percent,
                              title: '${data.percent.toStringAsFixed(1)}%\n${data.originalValueDisplay}', // Display percentage and then name
                              radius: sectionActualRadius,
                              titlePositionPercentageOffset: 0.55, 
                              titleStyle: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, 
                              ),
                              borderSide: isTouched 
                                  ? BorderSide(color: data.color.darken(0.2), width: 2)
                                  : BorderSide(color: data.color.darken(0.1), width: 1),
                            );
                          }).toList(),
                          startDegreeOffset: -90,
                        ),
                      ), // End of PieChart widget
                    ], // End of Stack's children list
                  ), // End of Stack widget
                ), // End of SizedBox widget
              ); // End of Center widget and the return statement
            },
          ),
        ),
      ],
    );
  }
}

// Extension to darken color for border
extension ColorUtil on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// Example Usage (typically in your PredictionGraphScreen):
//
// SleepFactorsPieChart(
//   chartTitle: "Factors contributing to sleep loss\n(noise level 80db)", // Example title
//   contributingFactors: { // This data would come from your PredictionModel
//     'Noise Level': 0.30, 
//     'High Temperature': 0.25,
//     'Dietary Variety': 0.10,
//     'Device Use': 0.15,
//     'Midnight Awakenings': 0.20,
//     // To get "High Temperature (40)", you might need to pass the actual value:
//     // 'High Temperature_actual_value': 40 
//     // ...and then modify _prepareChartData to use it for the label.
//   },
// )