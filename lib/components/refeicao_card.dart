// lib/components/refeicao_card.dart
import 'package:flutter/material.dart';

class RefeicaoCard extends StatelessWidget {
  final String imageUrl;
  final DateTime timestamp;
  final List<dynamic> alimentosLista;
  final int totalCalorias;
  final int totalProteinas;
  final int totalCarboidratos;
  final int totalGorduras;
  final VoidCallback onFavoritePressed;
  
  // NOVO: Flag para dizer ao card se ele é um favorito
  final bool isFavorito; 

  const RefeicaoCard({
    super.key,
    required this.imageUrl,
    required this.timestamp,
    required this.alimentosLista,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarboidratos,
    required this.totalGorduras,
    required this.onFavoritePressed,
    required this.isFavorito, // NOVO
  });

  @override
  Widget build(BuildContext context) {
    final String tituloAlimentos = alimentosLista.map((item) => item['alimento']).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // (Imagem - sem mudanças)
          Container(
            height: 200, width: double.infinity,
            child: Image.network(
              imageUrl, fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)),
            ),
          ),
          
          // (Texto - sem mudanças)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloAlimentos,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // MODIFICADO: O Ícone de Favoritar agora é "esperto"
                IconButton(
                  icon: Icon(
                    isFavorito ? Icons.star : Icons.star_border_outlined, // Lógica do ícone
                  ),
                  color: isFavorito 
                      ? Theme.of(context).colorScheme.primary // Cor se for favorito
                      : Colors.grey[400], // Cor se não for
                  tooltip: isFavorito ? "Salvo nos Favoritos" : "Salvar nos Favoritos",
                  onPressed: onFavoritePressed,
                ),
              ],
            ),
          ),
          
          // (Linha de Totais - sem mudanças)
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
  // (Widget auxiliar _buildTotalColumn - sem mudanças)
  Column _buildTotalColumn(String label, int value, [String sufixo = ""]) {
    return Column(
      children: [
        Text(value.toString() + sufixo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}