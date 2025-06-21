import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnvironmentalFactorsFormSection extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onDataCollected;

  const EnvironmentalFactorsFormSection({
    super.key,
    required this.onDataCollected,
  });

  @override
  EnvironmentalFactorsFormSectionState createState() => EnvironmentalFactorsFormSectionState();
}

class EnvironmentalFactorsFormSectionState extends State<EnvironmentalFactorsFormSection> {
  final TextEditingController _lightIntensityController = TextEditingController(text: '450');
  final TextEditingController _temperatureController = TextEditingController(text: '22');
  String _soundExposure = 'Quiet (< 30 dB)';

  final List<String> _soundExposureOptions = [
    'Quiet (< 30 dB)',
    'Moderate (30-60 dB)',
    'Loud (> 60 dB)',
  ];

  @override
  void initState() {
    super.initState();
    // Initial data collection call if needed, or rely on prepareAndValidateCurrentStep
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _collectData(); 
    // });
  }

  void _collectData() {
    final data = _buildEnvironmentalData();
    widget.onDataCollected(data);
  }

  Map<String, dynamic> _buildEnvironmentalData() {
    final lightValue = int.tryParse(_lightIntensityController.text) ?? 450;
    final tempValue = int.tryParse(_temperatureController.text) ?? 22;

    int soundValue;
    switch (_soundExposure) {
      case 'Quiet (< 30 dB)':
        soundValue = 25;
        break;
      case 'Moderate (30-60 dB)':
        soundValue = 45;
        break;
      case 'Loud (> 60 dB)':
        soundValue = 70;
        break;
      default:
        soundValue = 45; // Default to moderate if something unexpected happens
    }

    return {
      'lightIntensity': lightValue,
      'temperature': tempValue,
      'noiseLevel': soundValue,
      'humidity': 50, // Default value as per original screen
      'airQuality': 'Good', // Default value as per original screen
    };
  }

  Future<Map<String, dynamic>?> prepareAndValidateCurrentStep() async {
    // Basic validation: ensure text fields are not empty and parseable, though tryParse handles non-numbers.
    // More complex validation can be added here if needed.
    if (_lightIntensityController.text.isEmpty || _temperatureController.text.isEmpty) {
      // Optionally show a SnackBar or some other user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all environmental factor fields.')),
      );
      return null;
    }
    // Ensure values are parseable, otherwise _buildEnvironmentalData will use defaults
    if (int.tryParse(_lightIntensityController.text) == null || int.tryParse(_temperatureController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid numbers for light and temperature.')),
      );
      return null;
    }

    final data = _buildEnvironmentalData();
    widget.onDataCollected(data);
    return data;
  }

  @override
  void dispose() {
    _lightIntensityController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Factors',
            style: GoogleFonts.montaga(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF31244C)),
          ),
          const SizedBox(height: 24),

          // Light Intensity Input
          _buildLightIntensityInput(),
          const SizedBox(height: 20),

          // Temperature Input
          _buildTemperatureInput(),
          const SizedBox(height: 20),

          // Sound Exposure Input
          _buildSoundExposureInput(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLightIntensityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Light Intensity at Bedtime',
          style: GoogleFonts.montaga(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, // Take full width for better layout
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF31244C), width: 1.5),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lightIntensityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.start, // Align text to start
                  style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0), // Adjust padding
                    isDense: true,
                    hintText: 'e.g., 450',
                    hintStyle: GoogleFonts.montaga(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  onChanged: (_) => _collectData(), // Update data on change
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'lux',
                style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.wb_sunny_outlined,
                size: 22,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room Temperature',
          style: GoogleFonts.montaga(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, // Take full width
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF31244C), width: 1.5),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _temperatureController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.start, // Align text to start
                  style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0), // Adjust padding
                    isDense: true,
                    hintText: 'e.g., 22',
                    hintStyle: GoogleFonts.montaga(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  onChanged: (_) => _collectData(), // Update data on change
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '°C',
                style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.thermostat_outlined,
                size: 22,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundExposureInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typical Sound Exposure in Bedroom',
          style: GoogleFonts.montaga(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 0), // Reduced space before radio buttons
        ..._soundExposureOptions.map((option) => RadioListTile<String>(
          title: Text(
            option,
            style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
          ),
          value: option,
          groupValue: _soundExposure,
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _soundExposure = value;
              });
              _collectData(); // Update data on change
            }
          },
          activeColor: const Color(0xFF31244C),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Adjust padding
          dense: true, // Make tiles more compact
        )).toList(),
      ],
    );
  }
}
