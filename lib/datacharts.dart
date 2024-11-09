import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DataChartScreen extends StatelessWidget {
  final String fieldName;

  const DataChartScreen({super.key, required this.fieldName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF708291),
        title: Text(
          fieldName,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Negocios')
                    .where('Negocio', isEqualTo: FirebaseAuth.instance.currentUser!.displayName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<BarChartGroupData> barGroups = [];
                  List<double> scores = [];
                  double totalScore = 0;
                  int totalRatings = snapshot.data!.docs.length;
                  Map<int, int> frequencyMap = {};

                  // Define a list of colors to cycle through for each bar
                  List<Color> barColors = [
                    Colors.red,
                    Colors.yellow,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                    Colors.cyan,
                    Colors.indigo,
                    Colors.pink,
                    Colors.teal,
                  ];

                  for (int i = 0; i < totalRatings; i++) {
                    final doc = snapshot.data!.docs[i];
                    double score = double.parse(doc[fieldName].toString());
                    scores.add(score);
                    totalScore += score;

                    // Assign each bar a color from the list, cycling if needed
                    Color barColor = barColors[i % barColors.length];

                    barGroups.add(
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: score,
                            color: barColor,
                            width: 20,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                    );

                    int roundedScore = score.round();
                    frequencyMap[roundedScore] = (frequencyMap[roundedScore] ?? 0) + 1;
                  }

                  double average = totalScore / totalRatings;
                  int mostFrequentScore = frequencyMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
                  double maxScore = scores.reduce(max);
                  double minScore = scores.reduce(min);
                  double stdDeviation = calculateStandardDeviation(scores, average);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroups,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 2,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.black, fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(enabled: false),
                            alignment: BarChartAlignment.spaceEvenly,
                            maxY: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              'Analytics for $fieldName',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            Text(
                              'Average Score: ${(average * 10).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Most Indicated Score: $mostFrequentScore',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Maximum Score: ${maxScore.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Minimum Score: ${minScore.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Standard Deviation: ${stdDeviation.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Additional Insights',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            Text(
                              'This field’s average score shows overall customer satisfaction levels for $fieldName.',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const Text(
                              'The most frequently selected score indicates common user sentiment.',
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            Text(
                              'Understanding the range (min and max) and deviation can help in identifying consistency in feedback for $fieldName.',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to calculate standard deviation
double calculateStandardDeviation(List<double> scores, double average) {
  // ignore: avoid_types_as_parameter_names
  double sumOfSquaredDiffs = scores.fold(0, (sum, score) => sum + pow(score - average, 2));
  return sqrt(sumOfSquaredDiffs / scores.length);
}