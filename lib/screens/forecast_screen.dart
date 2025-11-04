import 'package:finance_mvp/widget/custom_segmented_control.dart';
import 'package:finance_mvp/widget/forecast/donut_chart.dart';
import 'package:finance_mvp/widget/forecast/goal_projection_card.dart';
import 'package:finance_mvp/widget/forecast/line_chart.dart';
import 'package:finance_mvp/widget/forecast/stat_card.dart';
import 'package:flutter/material.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  _ForecastScreenState createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Financial Forecast'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CustomSegmentedControl(
              //   segments: const ['Default', 'Optimistic', 'Pessimistic'],
              //   onSegmentChosen: (index) {
              //     setState(() {
              //       _selectedSegment = index;
              //     });
              //   },
              // ),
              const SizedBox(height: 16.0),
              const Row(
                children: [
                  StatCard(
                    title: 'Projected Net Worth',
                    value: '\$125,430',
                    percentage: '+2.5%',
                  ),
                  SizedBox(width: 16.0),
                  StatCard(
                    title: 'Estimated Savings',
                    value: '\$15,800',
                    percentage: '+5.1%',
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const LineChartCard(),
              const SizedBox(height: 16.0),
              const DonutChartCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
