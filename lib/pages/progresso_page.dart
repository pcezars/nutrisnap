// lib/pages/progresso_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pacote para formatar datas

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _historicoStream;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      // 1. Ouve o histórico de peso, ordenado do mais antigo para o mais novo
      _historicoStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('historicoPeso')
          .orderBy('timestamp', descending: false) // Importante: 'ascending' para o gráfico
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Progresso"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historicoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum registo de peso encontrado.\nVá à sua página de Perfil para adicionar o seu peso!",
                textAlign: TextAlign.center,
              ),
            );
          }

          // 2. TEMOS DADOS! Vamos mapeá-los para o gráfico
          final List<DocumentSnapshot> documentos = snapshot.data!.docs;
          
          // Converte os documentos do Firestore em "Pontos" (FlSpot)
          final List<FlSpot> spots = documentos.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final double peso = (data['peso'] as num).toDouble();
            
            // X: O timestamp (em milissegundos)
            // Y: O peso
            return FlSpot(timestamp.millisecondsSinceEpoch.toDouble(), peso);
          }).toList();

          // 3. Construir o Gráfico
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  "Evolução do Peso",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 300, // Altura do gráfico
                  child: LineChart(
                    _buildChartData(spots),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. A Função de Configuração do Gráfico (LineChartData)
  LineChartData _buildChartData(List<FlSpot> spots) {
    final Color corPrimaria = Theme.of(context).colorScheme.primary;

    return LineChartData(
      // Títulos (Eixos X e Y)
      titlesData: FlTitlesData(
        // Eixo Y (Peso)
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        // Desliga os títulos de cima e da direita
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        
        // Eixo X (Data)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calcularIntervaloX(spots), // Calcula o intervalo (para não sobrepor)
            // Formata o 'timestamp' de volta para uma data legível (ex: 02/Nov)
            getTitlesWidget: (value, meta) {
              final DateTime data = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(DateFormat('dd/MM').format(data), style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      
      // Grelha e Bordas
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!),
      ),
      
      // Os dados (a linha)
      lineBarsData: [
        LineChartBarData(
          spots: spots, // Os nossos dados!
          isCurved: true, // Linha curvada
          color: corPrimaria,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData( // Sombra por baixo da linha
            show: true,
            color: corPrimaria.withOpacity(0.2),
          ),
          dotData: const FlDotData(show: true), // Mostra os pontos
        ),
      ],
    );
  }
  
  // Função auxiliar para calcular o intervalo do eixo X
  double _calcularIntervaloX(List<FlSpot> spots) {
    if (spots.length < 2) return 1; // Intervalo padrão se não houver dados suficientes
    double minX = spots.first.x;
    double maxX = spots.last.x;
    // Tenta mostrar cerca de 4-5 datas no eixo X
    return (maxX - minX) / 4; 
  }
}