// lib/pages/onboarding_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Pega o usuário logado
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>(); // NOVO: Chave para validar o formulário
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _idadeController = TextEditingController();

  String? _sexoSelecionado;
  String? _metaSelecionada;
  bool _isLoading = false; // NOVO: Estado de loading

  // NOVO: Função para calcular TMB e Metas
  Map<String, double> _calcularMetas() {
    // 1. Converter inputs (com segurança)
    final double peso = double.tryParse(_pesoController.text) ?? 0;
    final double altura = double.tryParse(_alturaController.text) ?? 0;
    final int idade = int.tryParse(_idadeController.text) ?? 0;

    if (peso == 0 || altura == 0 || idade == 0 || _sexoSelecionado == null) {
      return {}; // Retorna vazio se os dados estiverem ruins
    }

    // 2. Calcular TMB (Taxa Metabólica Basal) - Fórmula de Harris-Benedict
    double tmb;
    if (_sexoSelecionado == 'Masculino') {
      // TMB = 66.5 + (13.75 * peso) + (5.003 * altura) - (6.75 * idade)
      tmb = 66.5 + (13.75 * peso) + (5.003 * altura) - (6.75 * idade);
    } else { // Feminino
      // TMB = 655.1 + (9.563 * peso) + (1.850 * altura) - (4.676 * idade)
      tmb = 655.1 + (9.563 * peso) + (1.850 * altura) - (4.676 * idade);
    }
    
    // 3. Ajustar TMB para TDEE (Gasto Calórico Diário Total)
    // Vamos assumir um fator de atividade leve (1.375) por padrão
    double tdee = tmb * 1.375;

    // 4. Calcular Meta Calórica com base no objetivo
    double metaCalorias;
    if (_metaSelecionada == 'Perder peso') {
      metaCalorias = tdee - 500; // Déficit de 500 kcal/dia (aprox -0.5kg/semana)
    } else if (_metaSelecionada == 'Ganhar peso') {
      metaCalorias = tdee + 500; // Superávit de 500 kcal/dia
    } else { // Manter peso
      metaCalorias = tdee;
    }

    // 5. Calcular Macros (Ex: 40% Carb, 30% Prot, 30% Gord)
    double metaProteinas = (metaCalorias * 0.30) / 4; // 1g proteína = 4 kcal
    double metaCarboidratos = (metaCalorias * 0.40) / 4; // 1g carb = 4 kcal
    double metaGorduras = (metaCalorias * 0.30) / 9; // 1g gordura = 9 kcal

    return {
      'metaCalorias': metaCalorias,
      'metaProteinas': metaProteinas,
      'metaCarboidratos': metaCarboidratos,
      'metaGorduras': metaGorduras,
      'tmb': tmb,
      'tdee': tdee,
    };
  }

  // MODIFICADO: Função de salvar agora calcula e salva no Firestore
  // MODIFICADO: Função de salvar agora calcula e salva no Firestore
  Future<void> _salvarPerfil() async {
    // 1. Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return; // Se o formulário for inválido, não faça nada
    }

    // MODIFICADO: Crie uma cópia local de 'currentUser'
    final User? user = currentUser;

    // MODIFICADO: Faça a checagem na cópia local
    if (user == null) {
      print("Erro ao salvar: Usuário não está logado.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Calcular as metas
      final Map<String, double> metas = _calcularMetas();

      if (metas.isEmpty) {
        throw Exception("Dados inválidos para cálculo.");
      }

      // 3. Salvar os dados no Firestore!
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid) // MODIFICADO: Use 'user.uid' (a variável local)
          .set({
        // Dados brutos
        'email': user.email, // MODIFICADO: Use 'user.email' (a variável local)
        'peso': _pesoController.text,
        'altura': _alturaController.text,
        'idade': _idadeController.text,
        'sexo': _sexoSelecionado,
        'metaObjetivo': _metaSelecionada,
        
        // Dados Calculados
        'metaCalorias': metas['metaCalorias'],
        'metaProteinas': metas['metaProteinas'],
        'metaCarboidratos': metas['metaCarboidratos'],
        'metaGorduras': metas['metaGorduras'],
        'tdee': metas['tdee'],
        
        'perfilCompleto': true, 
      });

      // (O resto da função 'try/catch/finally' continua igual)

    } catch (e) {
      print("Erro ao salvar perfil: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar perfil: $e")),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete seu Perfil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        // NOVO: Envolvendo a Coluna com um Form
        child: Form(
          key: _formKey, // Conectando a chave
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Precisamos de alguns dados para calcular suas metas nutricionais.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Sexo ---
              DropdownButtonFormField<String>(
                value: _sexoSelecionado,
                hint: const Text("Seu sexo biológico"),
                items: ['Masculino', 'Feminino']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() { _sexoSelecionado = value; });
                },
                // NOVO: Validação
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- Idade ---
              TextFormField(
                controller: _idadeController,
                decoration: const InputDecoration(labelText: "Idade (anos)"),
                keyboardType: TextInputType.number,
                // NOVO: Validação
                validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              
              // --- Peso ---
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(labelText: "Peso (kg)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- Altura ---
              TextFormField(
                controller: _alturaController,
                decoration: const InputDecoration(labelText: "Altura (cm)"),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- Meta ---
              DropdownButtonFormField<String>(
                value: _metaSelecionada,
                hint: const Text("Sua meta"),
                items: ['Perder peso', 'Manter peso', 'Ganhar peso']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() { _metaSelecionada = value; });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 40),

              // --- Botão Salvar ---
              ElevatedButton(
                // MODIFICADO: Desabilita se estiver carregando
                onPressed: _isLoading ? null : _salvarPerfil,
                child: _isLoading 
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                  : const Text("Salvar e Continuar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}