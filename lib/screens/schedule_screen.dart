import 'package:flutter/material.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int selectedDay = DateTime.now().day;
  late int weekOffset = (selectedDay - 1) ~/ daysPerPage; // auto page of current day
  static const int daysPerPage = 14;
  late final int totalDays = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
  final Map<int, List<Map<String, dynamic>>> scheduleByDay = {
    11: [
      {
        'time': '8:00am',
        'label': 'Wake Up',
        'color': Color(0xFFFFD6E0),
        'icon': Icons.wb_twilight,
        'checked': false,
      },
      {
        'time': '8:30am',
        'label': 'Break-fast',
        'color': Color(0xFFF7F7C6),
        'icon': Icons.free_breakfast,
        'checked': true,
      },
      {
        'time': '2:30pm',
        'label': 'Lunch',
        'color': Color(0xFFF7F7C6),
        'icon': Icons.lunch_dining,
        'checked': true,
      },
      {
        'time': '9:00pm',
        'label': 'Diner',
        'color': Color(0xFFF7F7C6),
        'icon': Icons.restaurant,
        'checked': true,
      },
      {
        'time': '9:00pm',
        'label': 'Sleep Time',
        'color': Color(0xFFF7F7C6),
        'icon': Icons.nightlight_round,
        'checked': false,
      },
    ],
    12: [
      {
        'time': '8:00am',
        'label': 'Wake Up',
        'color': Color(0xFFFFD6E0),
        'icon': Icons.wb_twilight,
        'checked': false,
      },
      {
        'time': '8:30am',
        'label': 'Break-fast',
        'color': Color(0xFFF7F7C6),
        'icon': Icons.free_breakfast,
        'checked': false,
      },
    ],
    // Add more days as needed
  };

  @override
  void initState() {
    super.initState();
    // Fetch schedules after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ScheduleProvider>();
      provider.fetchSchedules();
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2041),
      endDrawer: const CustomProfileDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2D2041),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TODAY IS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('d,MMMM yyyy').format(DateTime(DateTime.now().year, DateTime.now().month, selectedDay)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontFamily: 'Montaga',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: weekOffset > 0
                            ? () => setState(() {
                                  weekOffset--;
                                  selectedDay = weekOffset * daysPerPage + 1;
                                })
                            : null,
                        child: Icon(Icons.chevron_left,
                            color: weekOffset > 0 ? Colors.white : Colors.white24,
                            size: 28),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: (weekOffset + 1) * daysPerPage < totalDays
                            ? () => setState(() {
                                  weekOffset++;
                                  selectedDay = weekOffset * daysPerPage + 1;
                                })
                            : null,
                        child: Icon(Icons.chevron_right,
                            color: (weekOffset + 1) * daysPerPage < totalDays
                                ? Colors.white
                                : Colors.white24,
                            size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Removed arrow buttons from here
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (var day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (int i = 1; i <= 7; i++)
                                  Expanded(
                                    child: Center(
                                      child: Builder(
                                        builder: (context) {
                                          int day = weekOffset * daysPerPage + i;
                                          if (day > totalDays) return const SizedBox();
                                          return GestureDetector(
                                            onTap: () => setState(() => selectedDay = day),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (selectedDay == day)
                                                    ? const Color(0xFFFFD6E0)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  day.toString(),
                                                  style: TextStyle(
                                                    color: (selectedDay == day)
                                                        ? const Color(0xFF2D2041)
                                                        : Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (int i = 8; i <= 14; i++)
                                  Expanded(
                                    child: Center(
                                      child: Builder(
                                        builder: (context) {
                                          int day = weekOffset * daysPerPage + i;
                                          if (day > totalDays) return const SizedBox();
                                          return GestureDetector(
                                            onTap: () => setState(() => selectedDay = day),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (selectedDay == day)
                                                    ? const Color(0xFFFFD6E0)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  day.toString(),
                                                  style: TextStyle(
                                                    color: (selectedDay == day)
                                                        ? const Color(0xFF2D2041)
                                                        : Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Your Schedule',
                      style: TextStyle(
                        color: Color(0xFF2D2041),
                        fontSize: 20,
                        fontFamily: 'Montaga',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final scheduleProvider = Provider.of<ScheduleProvider>(context);
                            final scheduleByDay = scheduleProvider.scheduleByDay;
                            final isLoading = scheduleProvider.isLoading;
                            final error = scheduleProvider.error;
                            final schedule = scheduleByDay[selectedDay] ?? [];
                            if (isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (error != null && error.isNotEmpty) {
                              return Center(
                                child: Text(
                                  error,
                                  style: const TextStyle(color: Color(0xFF2D2041), fontSize: 16),
                                ),
                              );
                            }
                          if (schedule.isEmpty) {
                            return const Center(
                              child: Text(
                                'No events for this day.',
                                style: TextStyle(color: Color(0xFF2D2041), fontSize: 16),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: schedule.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ScheduleModel item = schedule[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: item.uiColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: item.checked
                                            ? const Icon(Icons.check, size: 12, color: Colors.black54)
                                            : null,
                                      ),
                                      if (index != schedule.length - 1)
                                        Container(
                                          width: 2,
                                          height: 48,
                                          color: const Color(0xFFDED6F3),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: item.uiColor,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(item.uiIcon, color: Colors.black54, size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.time,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.label,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 18,
                                                    fontFamily: 'Montserrat',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1,
        screenColor: Colors.white,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }
} 