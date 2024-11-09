import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'profile.dart';

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
                    const SizedBox(height: 16),
                    _buildChartsGrid(),
                    const Divider(),
                    const SizedBox(height: 8), // Added space to bring comments closer
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
              Image.asset('assets/images/logo_alt.png', height: 70),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: Column(
                  children: [
                    const Icon(Icons.account_circle, color: Color(0xFFFF8700), size: 50),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'User')
                          : 'Guest',
                      style: const TextStyle(color: Colors.black, fontSize: 15),
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
      height: 400, // Adjust height to control the square shape
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
  return SizedBox(
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
                    x: i, // Espacio más reducido entre barras
                    barRods: [
                      BarChartRodData(
                        toY: double.parse(doc[fieldName].toString()),
                        color: _getDynamicColor(i), // Color diferente para cada barra
                        width: 15, // Ajuste de ancho de barra para mejor visibilidad
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
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
                          // Puedes agregar títulos personalizados si es necesario
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  alignment: BarChartAlignment.spaceEvenly, // Distribución equilibrada de las barras
                  maxY: 10, // Escala ajustada al valor máximo esperado
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Color _getDynamicColor(int index) {
  // Asignar colores diferentes según el índice
  List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.yellow];
  return colors[index % colors.length];
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

        final comments = snapshot.data!.docs;
        return Column(
          children: comments.map((comment) {
            final feedback = comment['Feedback'];
            if (displayedFeedback.contains(feedback)) {
              return const SizedBox.shrink(); // Ignore duplicate comments
            }
            displayedFeedback.add(feedback);

            return Align(
              alignment: comment['Nombre'] == user.displayName
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: comment['Nombre'] == user.displayName
                      ? Colors.lightBlueAccent.withOpacity(0.3)
                      : Colors.yellowAccent.withOpacity(0.3),
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
            );
          }).toList(),
        );
      },
    );
  }
}
