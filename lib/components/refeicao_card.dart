// lib/components/refeicao_card.dart
import 'package:flutter/material.dart';

class RefeicaoCard extends StatelessWidget {
  final String imageUrl;
  final DateTime timestamp;
  
  // NOSSOS NOVOS CAMPOS:
  final List<dynamic> alimentosLista; // A lista de mapas
  final int totalCalorias;
  final int totalProteinas;
  final int totalCarboidratos;
  final int totalGorduras;

  const RefeicaoCard({
    super.key,
    required this.imageUrl,
    required this.timestamp,
    required this.alimentosLista,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarboidratos,
    required this.totalGorduras,
  });

  @override
  Widget build(BuildContext context) {
    // Cria um título a partir da lista (ex: "Arroz branco cozido, Feijão carioca cozido")
    final String tituloAlimentos = alimentosLista.map((item) => item['alimento']).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. A Imagem (como antes)
          Container(
            height: 200,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                    child: Icon(Icons.error, color: Colors.red));
              },
            ),
          ),
          
          // 2. O Texto e a Data
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloAlimentos, // Nosso novo título
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  // Data (como antes)
                  "${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // 3. NOVO: A Linha de Totais de Macros
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalColumn("Kcal", totalCalorias),
                _buildTotalColumn("Proteínas", totalProteinas, "g"),
                _buildTotalColumn("Carbos", totalCarboidratos, "g"),
                _buildTotalColumn("Gorduras", totalGorduras, "g"),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget auxiliar para a coluna de total (copiado da registro_page)
  Column _buildTotalColumn(String label, int value, [String sufixo = ""]) {
    return Column(
      children: [
        Text(
          value.toString() + sufixo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}