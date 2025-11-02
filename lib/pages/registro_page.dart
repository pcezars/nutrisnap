// lib/pages/registro_page.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_key.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  File? _imagemSelecionada;
  List<Map<String, dynamic>> _alimentosAnalisados = [];
  
  int _totalCalorias = 0;
  int _totalProteinas = 0;
  int _totalCarboidratos = 0;
  int _totalGorduras = 0;
  
  final ImagePicker _picker = ImagePicker();
  late final GenerativeModel _model;

  bool _isLoading = false; 
  bool _isAnalysing = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
    );
  }

  // MODIFICADO: Esta função agora salva a NOVA estrutura de dados
  Future<void> _salvarRefeicao() async {
    // 1. Validar se os campos estão preenchidos
    if (_imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione uma imagem.")),
      );
      return;
    }
    // MODIFICADO: Checa a lista, não o controller
    if (_alimentosAnalisados.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, aguarde a análise da IA.")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Inicia o loading do botão Salvar
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; 

      // 2. Fazer o upload da imagem (como antes)
      final String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference refStorage = FirebaseStorage.instance
          .ref()
          .child('refeicoes')
          .child(user.uid)
          .child('$nomeArquivo.jpg');

      await refStorage.putFile(_imagemSelecionada!);
      final String downloadUrl = await refStorage.getDownloadURL();

      // 3. MODIFICADO: Salvar os DADOS RICOS no Firestore
      await FirebaseFirestore.instance.collection('refeicoes').add({
        'userId': user.uid,
        'emailUsuario': user.email,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        
        // --- NOSSOS NOVOS CAMPOS ---
        'alimentosLista': _alimentosAnalisados, // A lista de mapas
        'totalCalorias': _totalCalorias,
        'totalProteinas': _totalProteinas,
        'totalCarboidratos': _totalCarboidratos,
        'totalGorduras': _totalGorduras,
      });

      // 4. Sucesso! (como antes)
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

  // (O resto do arquivo: _mostrarOpcoesEscolha, _pegarImagem, _analisarImagem, build, _buildListaAlimentos, _buildTotalColumn)
  // ... (NENHUMA OUTRA MUDANÇA É NECESSÁRIA) ...
  // ... (COLE O RESTANTE DO SEU ARQUIVO ANTIGO A PARTIR DAQUI) ...
  
  // (Função _mostrarOpcoesEscolha)
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

  // (Função _pegarImagem)
  Future<void> _pegarImagem(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(source: source);
      if (foto != null) {
        setState(() {
          _imagemSelecionada = File(foto.path);
          _alimentosAnalisados = []; // Limpa a análise anterior
        });
        _analisarImagem();
      }
    } catch (e) {
      print("Erro ao pegar imagem: $e");
    }
  }

  // (Função _analisarImagem)
  Future<void> _analisarImagem() async {
    if (_imagemSelecionada == null) return;

    setState(() {
      _isAnalysing = true;
      _totalCalorias = 0;
      _totalProteinas = 0;
      _totalCarboidratos = 0;
      _totalGorduras = 0;
    });

    try {
      final bytes = await _imagemSelecionada!.readAsBytes();
      final prompt = [
        Content.multi([
          TextPart(
              "Analise esta refeição. Estime os alimentos, gramas (g), calorias (kcal), proteínas (p), carboidratos (c) e gorduras (f). "
              "Responda APENAS com um array JSON. "
              "O array deve conter objetos com as chaves: 'alimento' (String), 'gramas' (int), 'calorias' (int), 'proteinas' (int), 'carboidratos' (int), 'gorduras' (int). "
              "Exemplo de formato: "
              "[{\"alimento\": \"Arroz branco\", \"gramas\": 150, \"calorias\": 200, \"proteinas\": 4, \"carboidratos\": 45, \"gorduras\": 0}, "
              "{\"alimento\": \"Feijão carioca\", \"gramas\": 100, \"calorias\": 90, \"proteinas\": 6, \"carboidratos\": 16, \"gorduras\": 0}]"
          ),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(prompt);

      if (response.text != null) {
        String jsonText = response.text!
            .replaceAll("```json", "")
            .replaceAll("```", "")
            .trim();
            
        final List<dynamic> jsonResponse = jsonDecode(jsonText);
        
        int tempCal = 0;
        int tempProt = 0;
        int tempCarb = 0;
        int tempGord = 0;

        final List<Map<String, dynamic>> alimentos = jsonResponse.map((item) {
          final map = item as Map<String, dynamic>;
          tempCal += (map['calorias'] as int? ?? 0);
          tempProt += (map['proteinas'] as int? ?? 0);
          tempCarb += (map['carboidratos'] as int? ?? 0);
          tempGord += (map['gorduras'] as int? ?? 0);
          return map;
        }).toList();
        
        setState(() {
          _alimentosAnalisados = alimentos;
          _totalCalorias = tempCal;
          _totalProteinas = tempProt;
          _totalCarboidratos = tempCarb;
          _totalGorduras = tempGord;
        });
      }
      
    } catch (e) {
      print("Erro ao analisar com Gemini: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao analisar imagem: $e")),
        );
      }
    } finally {
      setState(() {
        _isAnalysing = false;
      });
    }
  }

  // (Função build)
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
                            child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          ),
                  ),
                ),
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
            
            _buildListaAlimentos(),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarRefeicao,
              child: _isLoading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                  : const Text("Salvar Refeição"),
            )
          ],
        ),
      ),
    );
  }

  // (Função _buildListaAlimentos)
  Widget _buildListaAlimentos() {
    if (_alimentosAnalisados.isEmpty) {
      return const Center(
        child: Text("A análise da IA aparecerá aqui."),
      );
    }
    
    return Column(
      children: [
        const Text(
          "Análise da Refeição",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          itemCount: _alimentosAnalisados.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), 
          itemBuilder: (context, index) {
            final alimento = _alimentosAnalisados[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text("${alimento['alimento']} (${alimento['gramas']}g)"),
                subtitle: Text(
                  "Kcal: ${alimento['calorias']} | P: ${alimento['proteinas']}g | C: ${alimento['carboidratos']}g | G: ${alimento['gorduras']}g"
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        const Text(
          "Total da Refeição",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.green[50], 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalColumn("Kcal", _totalCalorias),
                _buildTotalColumn("Proteínas", _totalProteinas, "g"),
                _buildTotalColumn("Carbos", _totalCarboidratos, "g"),
                _buildTotalColumn("Gorduras", _totalGorduras, "g"),
              ],
            ),
          ),
        )
      ],
    );
  }

  // (Função _buildTotalColumn)
  Column _buildTotalColumn(String label, int value, [String sufixo = ""]) {
    return Column(
      children: [
        Text(
          value.toString() + sufixo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}