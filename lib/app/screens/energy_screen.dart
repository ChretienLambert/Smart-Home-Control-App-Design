import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'Week', 'Month', 'Year'];

  final Map<String, double> _energyData = {
    'Today': 12.4,
    'Week': 87.2,
    'Month': 354.8,
    'Year': 4256.3,
  };

  final List<Map<String, dynamic>> _deviceUsage = [
    {
      'name': 'Air Conditioner',
      'usage': 4.2,
      'percentage': 34,
      'icon': Icons.ac_unit,
      'color': Colors.blue,
    },
    {
      'name': 'Heating System',
      'usage': 3.1,
      'percentage': 25,
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
    {
      'name': 'Lighting',
      'usage': 2.8,
      'percentage': 23,
      'icon': Icons.lightbulb,
      'color': const Color(0xFFFFC857),
    },
    {
      'name': 'Entertainment',
      'usage': 1.5,
      'percentage': 12,
      'icon': Icons.tv,
      'color': Colors.purple,
    },
    {
      'name': 'Kitchen Appliances',
      'usage': 0.8,
      'percentage': 6,
      'icon': Icons.kitchen,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentUsage = _energyData[_selectedPeriod] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E7F5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Energy settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  final isSelected = period == _selectedPeriod;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF1E7F5C).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[300]!,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Current usage card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E7F5C),
                    Color(0xFF4ECDC4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Current Usage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${currentUsage.toStringAsFixed(1)} kWh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_selectedPeriod',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: const Color(0xFFFFC857),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '12% less than last $_selectedPeriod',
                        style: const TextStyle(
                          color: Color(0xFFFFC857),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Usage by device
            const Text(
              'Usage by Device',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ..._deviceUsage.map((device) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: device['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              device['icon'],
                              color: device['color'],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${device['usage']} kWh',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${device['percentage']}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: device['percentage'] / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(device['color']),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Energy saving tips
            const Text(
              'Energy Saving Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: const Color(0xFFFFC857),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tip of the Day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Turn off lights when leaving a room. This simple habit can save up to 10% on your energy bill.',
                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }
}
