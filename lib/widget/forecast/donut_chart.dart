import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutChartCard extends StatelessWidget {
  const DonutChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forecasted Spending Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$2,800',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  Text(
                    'This Month',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '-0.5%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: 40,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: Colors.teal,
                        value: 25,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: Colors.purple,
                        value: 15,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: Colors.grey.withOpacity(0.3),
                        value: 20,
                        title: '',
                        radius: 20,
                      ),
                    ],
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChartLegend(color: Colors.blue, text: 'Housing (40%)'),
                    SizedBox(height: 8.0),
                    ChartLegend(color: Colors.teal, text: 'Transport (25%)'),
                    SizedBox(height: 8.0),
                    ChartLegend(color: Colors.purple, text: 'Food (15%)'),
                    SizedBox(height: 8.0),
                    ChartLegend(color: Colors.grey, text: 'Other (20%)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  final Color color;
  final String text;

  const ChartLegend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(text),
      ],
    );
  }
}
