// lib/pages/registro_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// NOVO: Imports do Gemini
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_key.dart'; // Nossa chave de API secreta

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  File? _imagemSelecionada;
  final TextEditingController _alimentosController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // Loading do botão "Salvar"
  
  // NOVO: Loading do Gemini (enquanto analisa a imagem)
  bool _isAnalysing = false;
  
  // NOVO: Instância do Modelo do Gemini
  late final GenerativeModel _model;

  // NOVO: Inicializar o modelo do Gemini quando a tela abre
  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // O modelo que entende imagens
      apiKey: geminiApiKey,
    );
  }

  // (A função _salvarRefeicao continua igual à da Fase 3)
  Future<void> _salvarRefeicao() async {
    if (_imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione uma imagem.")),
      );
      return;
    }
    if (_alimentosController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, descreva os alimentos.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference refStorage = FirebaseStorage.instance
          .ref()
          .child('refeicoes')
          .child(user.uid)
          .child('$nomeArquivo.jpg');
      await refStorage.putFile(_imagemSelecionada!);
      final String downloadUrl = await refStorage.getDownloadURL();
      await FirebaseFirestore.instance.collection('refeicoes').add({
        'userId': user.uid,
        'emailUsuario': user.email,
        'alimentos': _alimentosController.text,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição salva com sucesso!")),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Erro ao salvar refeição: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // (A função _mostrarOpcoesEscolha continua igual)
  Future<void> _mostrarOpcoesEscolha() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  _pegarImagem(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pegarImagem(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // MODIFICADO: A função de pegar imagem agora chama a análise
  Future<void> _pegarImagem(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(source: source);
      if (foto != null) {
        setState(() {
          _imagemSelecionada = File(foto.path);
        });
        // NOVO: Chamar a IA logo após selecionar a foto
        _analisarImagem();
      }
    } catch (e) {
      print("Erro ao pegar imagem: $e");
    }
  }

  // NOVO: Função que chama o Gemini
  Future<void> _analisarImagem() async {
    if (_imagemSelecionada == null) return;

    setState(() {
      _isAnalysing = true; // Liga o loading da IA
    });

    try {
      // 1. Ler os bytes da imagem
      final bytes = await _imagemSelecionada!.readAsBytes();

      // 2. Criar a "pergunta" (prompt) para a IA
      final prompt = [
        Content.multi([
          TextPart(
              "Identifique os alimentos principais nesta imagem. "
              "Responda APENAS com os nomes dos alimentos, separados por vírgula e com a primeira letra maiúscula. "
              "Exemplo: Arroz, Feijão, Bife"),
          DataPart('image/jpeg', bytes),
        ])
      ];

      // 3. Enviar para a IA e obter a resposta
      final response = await _model.generateContent(prompt);

      // 4. Atualizar o campo de texto!
      setState(() {
        _alimentosController.text = response.text ?? 'Não foi possível identificar';
        _isAnalysing = false; // Desliga o loading da IA
      });
    } catch (e) {
      print("Erro ao analisar com Gemini: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao analisar imagem: $e")),
        );
        setState(() {
          _isAnalysing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Nova Refeição"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            // MODIFICADO: O container da imagem agora é um Stack
            // para mostrar o loading em cima da imagem.
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _mostrarOpcoesEscolha,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imagemSelecionada != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imagemSelecionada!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.camera_alt,
                                size: 50, color: Colors.grey),
                          ),
                  ),
                ),

                // NOVO: Overlay de Loading da IA
                if (_isAnalysing)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _alimentosController, // O Gemini vai preencher este!
              decoration: const InputDecoration(
                labelText: "Alimentos (ex: Arroz, Feijão, Bife)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _salvarRefeicao,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text("Salvar Refeição"),
            )
          ],
        ),
      ),
    );
  }
}