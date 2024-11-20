import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'profile.dart';
import 'comment.dart';
import 'datacharts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Set<String> displayedFeedback = {}; // For duplicate check in comments

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF708291),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Container(
                margin: const EdgeInsets.only(top: 1, left: 16, right: 16),
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 120,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChartsGrid(),
                    const SizedBox(height: 8),
                    _buildAverageIndicators(),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Comments',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/logo.png', height: 80),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: Column(
                  children: [
                    user?.photoURL != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user!.photoURL!),
                            radius: 25,
                          )
                        : const Icon(
                            Icons.account_circle,
                            color: Color(0xFFFF8700),
                            size: 50,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'User')
                          : 'Guest',
                      style: const TextStyle(color: Color(0xFFFF8700), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildChartsGrid() {
    return SizedBox(
      height: 350,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildBarChart('Ambiente'),
          _buildBarChart('Calidad'),
          _buildBarChart('Recomendacion'),
          _buildBarChart('Servicio'),
        ],
      ),
    );
  }

  Widget _buildBarChart(String fieldName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DataChartScreen(fieldName: fieldName),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fieldName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
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
                  for (int i = 0; i < snapshot.data!.docs.length; i++) {
                    final doc = snapshot.data!.docs[i];
                    barGroups.add(
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: double.parse(doc[fieldName].toString()),
                            color: _getDynamicColor(i),
                            width: 15,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                    );
                  }

                  return BarChart(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDynamicColor(int index) {
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.yellow];
    return colors[index % colors.length];
  }

  Widget _buildAverageIndicators() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Negocios')
          .where('Negocio', isEqualTo: user!.displayName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available.'));
        }

        double calculateAverage(String field) {
          final values = snapshot.data!.docs.map((doc) => double.parse(doc[field].toString())).toList();
          final sum = values.reduce((a, b) => a + b);
          return sum / values.length;
        }

        final ambienteAvg = calculateAverage('Ambiente');
        final calidadAvg = calculateAverage('Calidad');
        final recomendacionAvg = calculateAverage('Recomendacion');
        final servicioAvg = calculateAverage('Servicio');

        return SizedBox(
          height: 180,
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAverageBox('Ambiente', ambienteAvg),
              _buildAverageBox('Calidad', calidadAvg),
              _buildAverageBox('Recomendacion', recomendacionAvg),
              _buildAverageBox('Servicio', servicioAvg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAverageBox(String fieldName, double average) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            fieldName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            '${(average * 10).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.displayName == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Negocios')
          .where('Negocio', isEqualTo: user.displayName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No comments available.');
        }

        // Clear the set each time new data is fetched to avoid duplicate checking issues
        displayedFeedback.clear();

        final comments = snapshot.data!.docs;
        return Column(
          children: comments.map((comment) {
            final feedback = comment['Feedback'];
            if (displayedFeedback.contains(feedback)) {
              return const SizedBox.shrink();
            }
            displayedFeedback.add(feedback);

            return Align(
              alignment: comment['Nombre'] == user.displayName
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentScreen(
                        initialComment: feedback,
                        commentId: comment.id, // Pass comment ID
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: comment['Nombre'] == user.displayName
                        ? Colors.lightBlueAccent.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${comment['Nombre']} (${comment['Numero']})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
