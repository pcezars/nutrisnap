// lib/pages/perfil_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// MODIFICADO: Convertido para StatefulWidget
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  // NOVO: Controladores e estado para o novo formulário
  final _pesoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // NOVO: Função para salvar o peso atual
  Future<void> _salvarPesoAtual() async {
    // 1. Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (currentUser == null) return;
    
    // 2. Converter o peso
    final double? peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    if (peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, insira um peso válido.")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 3. Salvar na nova subcoleção
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser!.uid)
          .collection('historicoPeso') // A nossa nova coleção de histórico
          .add({
        'peso': peso,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Peso salvo com sucesso! ⚖️")),
        );
        _pesoController.clear(); // Limpa o campo
      }

    } catch (e) {
      print("Erro ao salvar peso: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar peso: $e")),
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
        title: const Text("Perfil"),
      ),
      // MODIFICADO: Envolvido num SingleChildScrollView
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Secção de Informações (Como antes) ---
                const Icon(Icons.person, size: 80),
                const SizedBox(height: 10),
                Text(
                  "Logado como:",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  currentUser?.email ?? 'E-mail não encontrado',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                const Divider(),
                const SizedBox(height: 30),

                // --- NOVO: Secção de Registo de Peso ---
                Text(
                  "Registar Peso Atual",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // O Campo de Texto
                      Expanded(
                        child: TextFormField(
                          controller: _pesoController,
                          decoration: const InputDecoration(
                            labelText: "Peso atual (kg)",
                            suffixIcon: Icon(Icons.scale),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obrigatório';
                            }
                            final n = double.tryParse(value.replaceAll(',', '.'));
                            if (n == null || n <= 0) {
                              return 'Peso inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // O Botão Salvar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _salvarPesoAtual,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Icon(Icons.save),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 40),

                // --- Secção de Logout (Como antes) ---
                ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text("Sair"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}