import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_statuses.dart';
import '../models/report_model.dart';

class AdminActivityChart extends StatelessWidget {
  final List<ReportModel> reports;

  const AdminActivityChart({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final gridColor = isDark ? Colors.white12 : AppColors.divider;

    // 1. Calculate the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    // 2. Group counts: [Total, Resolved, In Progress] for each day
    final List<List<double>> dailyData = List.generate(7, (_) => [0.0, 0.0, 0.0]);

    for (final report in reports) {
      for (int i = 0; i < 7; i++) {
        if (report.createdAt.year == last7Days[i].year &&
            report.createdAt.month == last7Days[i].month &&
            report.createdAt.day == last7Days[i].day) {
          
          dailyData[i][0] += 1; // Total
          
          if (report.status == ReportStatus.verified) {
            dailyData[i][1] += 1; // Resolved
          } else if (report.status == ReportStatus.inProgress || report.status == ReportStatus.assigned) {
            dailyData[i][2] += 1; // In Progress
          }
          break;
        }
      }
    }

    // Find the max Y value for scaling
    double maxY = 0;
    for (var day in dailyData) {
      for (var count in day) {
        if (count > maxY) maxY = count;
      }
    }
    final safeMaxY = maxY == 0 ? 5.0 : maxY + 2;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot('Total', AppColors.primary, textColor),
            const SizedBox(width: 16),
            _legendDot('Resolved', AppColors.success, textColor),
            const SizedBox(width: 16),
            _legendDot('In Progress', AppColors.statusInProgress, textColor),
          ],
        ),
        const SizedBox(height: 20),
        
        // Chart
        SizedBox(
          height: 270,
          child: BarChart(
            BarChartData(
              maxY: safeMaxY,
              barTouchData: BarTouchData(
                 enabled: false, 
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      final date = last7Days[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM').format(date),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(color: AppColors.textHint, fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (index) {
                return BarChartGroupData(
                  x: index,
                  barsSpace: 2,
                  barRods: [
                    BarChartRodData(
                      toY: dailyData[index][0],
                      color: AppColors.primary,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: dailyData[index][1],
                      color: AppColors.success,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: dailyData[index][2],
                      color: AppColors.statusInProgress,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}