import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/widgets/goal_projection_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _chartToggle = 0;
  int _filterTime = 2;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : context.colors.background;
    final textColor =
        isDarkMode ? AppColors.darkPrimary : context.colors.textDark;
    final cardBackgroundColor = isDarkMode
        ? AppColors.darkCardBackground
        : context.colors.cardBackground;
    final segmentedControlBackgroundColor = isDarkMode
        ? AppColors.darkSegmentedControlBackground
        : context.colors.segmentedControlBackground;
    final segmentedControlActiveColor = isDarkMode
        ? AppColors.darkSegmentedControlActive
        : context.colors.segmentedControlActive;
    final primaryColor = context.colors.primaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopAppBar(textColor),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Total Balance',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<String>(
                future: _loadTotalBalance(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? '\$0.00',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildChartSection(
                    context,
                    cardBackgroundColor,
                    segmentedControlBackgroundColor,
                    segmentedControlActiveColor,
                    primaryColor,
                    textColor,
                  ),
                ],
              ),
            ),
            _buildBottomFilterBar(context, primaryColor),
          ],
        ),
      ),
    );
  }

  Future<String> _loadTotalBalance() async {
    final repo = context.read<FinanceRepository>();
    final total =
        await repo.calculateTotalBalance(await repo.getBaseCurrencyCode());
    return formatMoney(total, symbol: await repo.getBaseCurrencySymbol());
  }

  Future<({double value, String symbol})> _loadMonthNet() async {
    final repo = context.read<FinanceRepository>();
    final summary = await repo.watchMonthlySummary(DateTime.now()).first;
    return (
      value: summary.income - summary.expenses,
      symbol: await repo.getBaseCurrencySymbol(),
    );
  }

  Widget _buildTopAppBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Text(
            'Dashboard',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    Color cardBackgroundColor,
    Color segmentedControlBackgroundColor,
    Color segmentedControlActiveColor,
    Color primaryColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          _buildSegmentedControl(segmentedControlBackgroundColor,
              segmentedControlActiveColor, primaryColor, textColor),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              FutureBuilder<({double value, String symbol})>(
                future: _loadMonthNet(),
                builder: (context, snapshot) {
                  final value = snapshot.data?.value ?? 0.0;
                  final symbol = snapshot.data?.symbol ?? r'$';
                  return Text(
                    formatMoney(value, symbol: symbol),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'This month',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder for the chart
          SizedBox(
            height: 150,
            width: double.infinity,
            // Replace with actual chart widget
            child: CustomPaint(
              painter: _ChartPainter(primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('7', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('14', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('21', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('30', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Goal Projections',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16.0),
          const GoalProjectionCard(
            title: 'Emergency Fund',
            projectedDate: 'Dec 2024',
            currentAmount: '8k',
            totalAmount: '10k',
            progress: 0.8,
            icon: Icons.shield,
          ),
          const SizedBox(height: 16.0),
          const GoalProjectionCard(
            title: 'Vacation to Italy',
            projectedDate: 'Jun 2025',
            currentAmount: '2k',
            totalAmount: '5k',
            progress: 0.4,
            icon: Icons.beach_access,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(Color backgroundColor, Color activeColor,
      Color primaryColor, Color textColor) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          _buildSegmentedControlItem(0, 'Spending', activeColor, textColor),
          _buildSegmentedControlItem(1, 'Income', activeColor, textColor),
        ],
      ),
    );
  }

  Widget _buildSegmentedControlItem(
    int index,
    String text,
    Color activeColor,
    Color primaryColor,
  ) {
    final bool isSelected = _chartToggle == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _chartToggle = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFilterBar(BuildContext context, Color primaryColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final barBackgroundColor =
        isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: barBackgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFilterItem(0, 'D', primaryColor),
            _buildFilterItem(1, 'W', primaryColor),
            _buildFilterItem(2, 'M', primaryColor),
            _buildFilterItem(3, 'Y', primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(int index, String text, Color primaryColor) {
    final bool isSelected = _filterTime == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterTime = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color primaryColor;

  _ChartPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.726); // 109 / 150
    path.cubicTo(
        size.width * 0.0385,
        size.height * 0.726, // 18.15 / 472
        size.width * 0.0385,
        size.height * 0.14, // 21 / 150
        size.width * 0.0769,
        size.height * 0.14); // 36.3 / 472
    path.cubicTo(
        size.width * 0.115,
        size.height * 0.14, // 54.46 / 472
        size.width * 0.115,
        size.height * 0.273, // 41 / 150
        size.width * 0.153,
        size.height * 0.273); // 72.6 / 472
    path.cubicTo(
        size.width * 0.192,
        size.height * 0.273, // 90.76 / 472
        size.width * 0.192,
        size.height * 0.62, // 93 / 150
        size.width * 0.23,
        size.height * 0.62); // 108.9 / 472
    path.cubicTo(
        size.width * 0.269,
        size.height * 0.62, // 127.07 / 472
        size.width * 0.269,
        size.height * 0.22, // 33 / 150
        size.width * 0.307,
        size.height * 0.22); // 145.23 / 472
    path.cubicTo(
        size.width * 0.346,
        size.height * 0.22, // 163.38 / 472
        size.width * 0.346,
        size.height * 0.673, // 101 / 150
        size.width * 0.384,
        size.height * 0.673); // 181.53 / 472
    path.cubicTo(
        size.width * 0.423,
        size.height * 0.673, // 199.69 / 472
        size.width * 0.423,
        size.height * 0.406, // 61 / 150
        size.width * 0.461,
        size.height * 0.406); // 217.84 / 472
    path.cubicTo(
        size.width * 0.5,
        size.height * 0.406, // 236 / 472
        size.width * 0.5,
        size.height * 0.3, // 45 / 150
        size.width * 0.538,
        size.height * 0.3); // 254.15 / 472
    path.cubicTo(
        size.width * 0.576,
        size.height * 0.3, // 272.3 / 472
        size.width * 0.576,
        size.height * 0.806, // 121 / 150
        size.width * 0.615,
        size.height * 0.806); // 290.46 / 472
    path.cubicTo(
        size.width * 0.653,
        size.height * 0.806, // 308.6 / 472
        size.width * 0.653,
        size.height * 0.993, // 149 / 150
        size.width * 0.692,
        size.height * 0.993); // 326.76 / 472
    path.cubicTo(
        size.width * 0.73,
        size.height * 0.993, // 344.92 / 472
        size.width * 0.73,
        size.height * 0.006, // 1 / 150
        size.width * 0.769,
        size.height * 0.006); // 363.07 / 472
    path.cubicTo(
        size.width * 0.807,
        size.height * 0.006, // 381.23 / 472
        size.width * 0.807,
        size.height * 0.54, // 81 / 150
        size.width * 0.846,
        size.height * 0.54); // 399.38 / 472
    path.cubicTo(
        size.width * 0.884,
        size.height * 0.54, // 417.53 / 472
        size.width * 0.884,
        size.height * 0.86, // 129 / 150
        size.width * 0.923,
        size.height * 0.86); // 435.69 / 472
    path.cubicTo(
        size.width * 0.961,
        size.height * 0.86, // 453.84 / 472
        size.width * 0.961,
        size.height * 0.166, // 25 / 150
        size.width,
        size.height * 0.166); // 472 / 472

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.2),
          primaryColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
