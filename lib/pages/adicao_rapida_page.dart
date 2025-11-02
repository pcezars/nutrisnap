// lib/pages/adicao_rapida_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdicaoRapidaPage extends StatefulWidget {
  const AdicaoRapidaPage({super.key});

  @override
  State<AdicaoRapidaPage> createState() => _AdicaoRapidaPageState();
}

class _AdicaoRapidaPageState extends State<AdicaoRapidaPage> {
  // NOVO: O URL da sua imagem placeholder que você carregou
  final String _placeholderImageUrl = "https://firebasestorage.googleapis.com/v0/b/nutrisnap-e98f5.firebasestorage.app/o/refeicoes%2Fplaceholder.png?alt=media&token=6bacade4-23e6-4868-8ee9-d79d815ae4ad"; 

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _kcalController = TextEditingController();
  final _protController = TextEditingController();
  final _carbController = TextEditingController();
  final _gordController = TextEditingController();
  
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // A Lógica para salvar a entrada manual
  Future<void> _salvarAdicaoRapida() async {
    // 1. Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    if (currentUser == null) return;

    setState(() { _isLoading = true; });

    try {
      // 2. Converter os dados do formulário
      final String nome = _nomeController.text;
      final int totalCalorias = int.tryParse(_kcalController.text) ?? 0;
      final int totalProteinas = int.tryParse(_protController.text) ?? 0;
      final int totalCarboidratos = int.tryParse(_carbController.text) ?? 0;
      final int totalGorduras = int.tryParse(_gordController.text) ?? 0;

      // 3. Criar a estrutura de dados "rica" (compatível com o RefeicaoCard)
      final Map<String, dynamic> dadosRefeicao = {
        'userId': currentUser!.uid,
        'emailUsuario': currentUser!.email,
        'imageUrl': _placeholderImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        
        // Criamos uma lista "falsa" para o card exibir o nome
        'alimentosLista': [
          {
            'alimento': nome,
            'gramas': 0, // Não pedimos gramas
            'calorias': totalCalorias,
            'proteinas': totalProteinas,
            'carboidratos': totalCarboidratos,
            'gorduras': totalGorduras,
          }
        ],
        
        // Os totais
        'totalCalorias': totalCalorias,
        'totalProteinas': totalProteinas,
        'totalCarboidratos': totalCarboidratos,
        'totalGorduras': totalGorduras,
      };

      // 4. Salvar na coleção 'refeicoes'
      await FirebaseFirestore.instance.collection('refeicoes').add(dadosRefeicao);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição rápida adicionada! 💪")),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      print("Erro ao salvar adição rápida: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adição Rápida"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        // O Formulário
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Registre uma refeição rápida (como uma barra de proteína ou uma fruta) inserindo os macros totais.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Nome ---
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome da Refeição (ex: Barra de Proteína)"),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- Calorias ---
              TextFormField(
                controller: _kcalController,
                decoration: const InputDecoration(labelText: "Total de Calorias (kcal)"),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              
              // --- Macros (linha) ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _protController,
                      decoration: const InputDecoration(labelText: "Proteínas (g)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _carbController,
                      decoration: const InputDecoration(labelText: "Carbos (g)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _gordController,
                      decoration: const InputDecoration(labelText: "Gorduras (g)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- Botão Salvar ---
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarAdicaoRapida,
                child: _isLoading 
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                  : const Text("Salvar Refeição Rápida"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}