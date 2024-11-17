import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logger.dart';
import '../../providers/receipt_provider.dart';
import '../components/custom_app_bar.dart';
import '../constants/app_colors.dart';

class ReportPage extends StatefulWidget {
  static const String id = 'report_page';

  const ReportPage({super.key});

  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  TimeInterval selectedInterval =
      TimeInterval.day; // Default time interval (day)

  bool isPieChart = true; // Toggle state for chart
  String currencySymbol = '€';

  @override
  void initState() {
    super.initState();

    // Safe asynchronous execution to avoid build conflicts
    Future.microtask(() async {
      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      logger.i("Initializing ReportPage...");
      logger.i("Fetching initial data.");

      // Fetch initial receipts and grouping
      await receiptProvider.fetchReceipts();
      receiptProvider.groupByCategory();

      // Generate colors for each category
      setState(() {
        currencySymbol =
            receiptProvider.currencySymbol ?? '€'; // Fetch the symbol
      });
    });
  }

  List<PieChartSectionData> getPieSections(
      Map<String, Map<String, dynamic>> groupedReceiptsByCategory) {
    if (groupedReceiptsByCategory.isEmpty) return [];

    return groupedReceiptsByCategory.entries.map((entry) {
      final total = entry.value['total'] as double? ?? 0.0;
      final categoryColor =
          entry.value['color'] as Color? ?? Colors.grey.shade200;

      return PieChartSectionData(
        color: categoryColor,
        value: total,
        title: '', // Set the title to empty
        radius: 70,
        titleStyle:
            TextStyle(fontSize: 0), // Set title style font size to 0 to hide it
      );
    }).toList();
  }

// Method to build the pie chart
  Widget buildPieChart(BuildContext context) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    // Get the grouped receipts by category
    final groupedReceipts = receiptProvider.groupedReceiptsByCategory ?? {};

    // Debug print for grouped receipts
    print(groupedReceipts);

    // Check if groupedReceipts is empty
    if (groupedReceipts.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    // Calculate the total amount
    final totalAmount = groupedReceipts.values.fold(
      0.0,
      (sum, item) => sum + (item['total'] as double? ?? 0.0), // Access 'total'
    );

    // Build the pie chart
    return Column(
      children: [
        SizedBox(
          height: 300, // Fixed height for the pie chart
          child: PieChart(
            PieChartData(
              sections: groupedReceipts.entries.map((entry) {
                // Extract fields for each category
                final total = entry.value['total'] as double? ?? 0.0;
                final percentage = (total / totalAmount) * 100;
                final categoryColor =
                    entry.value['color'] as Color? ?? Colors.grey.shade200;

                return PieChartSectionData(
                  color: categoryColor, // Use grey if no color
                  value: total,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 60,
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 20), // Space between chart and legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groupedReceipts.entries.map((entry) {
            final categoryData = entry.value;

            final total = categoryData['total'] as double? ?? 0.0;
            final percentage = (total / totalAmount) * 100;

            final categoryName = categoryData['name'] ?? 'Uncategorized';
            final categoryIcon = categoryData['icon'] ?? '❓';
            final categoryColor = categoryData['color'] ?? Colors.grey.shade200;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Icon with background color
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: categoryColor, // Background color
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text(
                              categoryIcon, // Use emoji/icon string
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8), // Spacing between icon and text
                        // Category name and details
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              '$categoryName: $currencySymbol ${total.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<BarChartGroupData> getBarChartGroups(BuildContext context) {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    final groupedReceipts = receiptProvider.groupedReceiptsByInterval ?? {};

    return groupedReceipts.entries.map((entry) {
      final index = groupedReceipts.keys.toList().indexOf(entry.key);
      final total = entry.value;
      final color = Color(0xFF66BB6A);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: color,
            width: 22,
            borderRadius: BorderRadius.circular(1),
            // Add a label for the value above the bar
            rodStackItems: [
              BarChartRodStackItem(0, total, color),
            ],
          ),
        ],
        // Show tooltip or indicator with value above the bar
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  Widget buildBarChart(BuildContext context, TimeInterval interval) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    // Ensure data is grouped by interval before building the chart
    receiptProvider.groupByInterval(interval);

    final groupedReceipts = receiptProvider.groupedReceiptsByInterval ?? {};

    if (groupedReceipts.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    final chartWidth = groupedReceipts.length * 100.0;
    final maxY = groupedReceipts.values
            .fold(0.0, (prev, next) => prev > next ? prev : next) *
        1.1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 350, // Set the minimum width
          maxWidth: double.infinity, // You can set the maximum width as needed
        ),
        child: SizedBox(
          width: chartWidth,
          height: 300,
          child: BarChart(BarChartData(
            maxY: maxY, // Set maxY based on calculated max value
            alignment: BarChartAlignment.spaceEvenly,
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide the top axis titles
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Display the interval (day, week, month, or year) as the title

                    final key = groupedReceipts.keys.elementAt(value.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        key, // Display the grouped interval as the label
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                  reservedSize: 42,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide the left axis values
                ),
              ),
            ),

            barGroups: getBarChartGroups(context),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '$currencySymbol ${rod.toY.toStringAsFixed(1)}', // Add the currency symbol
                    const TextStyle(
                      color: Colors.black, // Tooltip text color
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
                getTooltipColor: (group) =>
                    Colors.transparent, // Set background color
                tooltipPadding:
                    const EdgeInsets.all(0), // Padding inside the tooltip
                tooltipMargin: 0, // Margin from the bar
              ),
            ),
          )),
        ),
      ),
    );
  }

// Method to build a customizable card with dynamic content
  Widget buildCard({
    required BuildContext context,
    required String title,
    required Widget content, // Dynamic content to display inside the card
    double elevation = 4, // Card elevation
    EdgeInsets padding = const EdgeInsets.all(10.0), // Padding inside the card
    double borderRadius = 10.0, // Border radius
  }) {
    return Card(
      color: Colors.white, // Set the background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius), // Rounded corners
      ),
      elevation: elevation, // Shadow effect
      child: Padding(
        padding: padding, // Add customizable padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16), // Space between title and content
            content, // Display dynamic content (e.g., chart, text, etc.)
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? purple100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light90,
      appBar: CustomAppBar(),
      body: Consumer<ReceiptProvider>(
        builder: (context, receiptProvider, child) {
          if (receiptProvider.allReceipts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Button for Bar Chart and Pie Chart
                  Row(
                    children: [
                      // Bar Chart Button with rounded left corners
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isPieChart = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isPieChart ? Colors.white : purple80,
                          minimumSize: const Size(
                              10, 50), // Adjust width and height if necessary
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            side: BorderSide(
                              color: isPieChart
                                  ? light60
                                  : Colors
                                      .transparent, // Border only when inactive
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.bar_chart, // Use preferred icon for bar chart
                          color: isPieChart ? purple80 : light60,
                        ),
                      ),
                      // Pie Chart Button with rounded right corners
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isPieChart = true;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isPieChart ? purple80 : Colors.white,
                          minimumSize: const Size(10, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            side: BorderSide(
                              color: isPieChart
                                  ? Colors.transparent
                                  : light60, // Border only when inactive
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: isPieChart ? light80 : purple100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isPieChart)
                    buildCard(
                      context: context,
                      title: 'Expenses by Category',
                      content:
                          buildPieChart(context), // Uses Consumer internally
                    )
                  else ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        spacing: 8,
                        children: TimeInterval.values
                            .map((interval) => _buildFilterOption(
                                  label: interval.name.toUpperCase(),
                                  isSelected: receiptProvider
                                          .selectedInterval ==
                                      interval, // Access directly from provider
                                  onSelected: (_) {
                                    receiptProvider.updateInterval(interval);
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildCard(
                      context: context,
                      title:
                          'Expenses by ${receiptProvider.selectedInterval.name}',
                      content: buildBarChart(
                        context,
                        receiptProvider.selectedInterval,
                      ), // Uses Consumer internally
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
