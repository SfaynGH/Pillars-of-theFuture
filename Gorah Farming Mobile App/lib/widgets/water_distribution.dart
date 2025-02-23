import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterDistributionWidget extends StatelessWidget {
  final List<double> adjustedWaterDistribution;
  final double soilMoistureIndex;
  final double waterNeededNext7Days;

  const WaterDistributionWidget({
    super.key,
    required this.adjustedWaterDistribution,
    required this.soilMoistureIndex,
    required this.waterNeededNext7Days,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Distribution Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Soil Moisture Index Indicator
            Row(
              children: [
                const Text('Soil Moisture Index: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: soilMoistureIndex,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(soilMoistureIndex * 100).toStringAsFixed(1)}%'),
              ],
            ),

            const SizedBox(height: 24),

            // Water Distribution Chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('Day ${value.toInt() + 1}');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  barGroups: adjustedWaterDistribution.asMap().entries.map(
                        (entry) => BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(), // Ensure value is double
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4), // Optional rounded bars
                        ),
                      ],
                    ),
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Total Water Needed
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Water Needed (7 Days):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${waterNeededNext7Days.toStringAsFixed(2)} mm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}