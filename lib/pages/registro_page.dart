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

class RegistroPage extends StatefulWidget { // <--- ESTE É O NOME CORRETO
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

  Future<void> _salvarRefeicao() async {
    if (_imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione uma imagem.")),
      );
      return;
    }
    if (_alimentosAnalisados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum alimento analisado para salvar.")),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference refStorage = FirebaseStorage.instance
          .ref().child('refeicoes').child(user.uid).child('$nomeArquivo.jpg');
      await refStorage.putFile(_imagemSelecionada!);
      final String downloadUrl = await refStorage.getDownloadURL();
      await FirebaseFirestore.instance.collection('refeicoes').add({
        'userId': user.uid,
        'emailUsuario': user.email,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'alimentosLista': _alimentosAnalisados,
        'totalCalorias': _totalCalorias,
        'totalProteinas': _totalProteinas,
        'totalCarboidratos': _totalCarboidratos,
        'totalGorduras': _totalGorduras,
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
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _mostrarOpcoesEscolha() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library), title: const Text('Galeria'),
                onTap: () { _pegarImagem(ImageSource.gallery); Navigator.of(context).pop(); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera), title: const Text('Câmera'),
                onTap: () { _pegarImagem(ImageSource.camera); Navigator.of(context).pop(); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pegarImagem(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(source: source);
      if (foto != null) {
        setState(() {
          _imagemSelecionada = File(foto.path);
          _alimentosAnalisados = [];
        });
        _analisarImagem();
      }
    } catch (e) { print("Erro ao pegar imagem: $e"); }
  }

  Future<void> _analisarImagem() async {
    if (_imagemSelecionada == null) return;
    setState(() { _isAnalysing = true; });
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
        String jsonText = response.text!.replaceAll("```json", "").replaceAll("```", "").trim();
        final List<dynamic> jsonResponse = jsonDecode(jsonText);
        final List<Map<String, dynamic>> alimentos = jsonResponse.map((item) {
          return item as Map<String, dynamic>;
        }).toList();
        setState(() {
          _alimentosAnalisados = alimentos;
        });
        _recalcularTotais();
      }
    } catch (e) {
      print("Erro ao analisar com Gemini: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao analisar imagem: $e")),
        );
      }
    } finally {
      setState(() { _isAnalysing = false; });
    }
  }

  void _recalcularTotais() {
    int tempCal = 0, tempProt = 0, tempCarb = 0, tempGord = 0;
    for (final item in _alimentosAnalisados) {
      tempCal += (item['calorias'] as int? ?? 0);
      tempProt += (item['proteinas'] as int? ?? 0);
      tempCarb += (item['carboidratos'] as int? ?? 0);
      tempGord += (item['gorduras'] as int? ?? 0);
    }
    setState(() {
      _totalCalorias = tempCal;
      _totalProteinas = tempProt;
      _totalCarboidratos = tempCarb;
      _totalGorduras = tempGord;
    });
  }

  Future<void> _mostrarDialogoEdicao({Map<String, dynamic>? item, int? index}) async {
    final bool isEditMode = item != null;
    final _formKey = GlobalKey<FormState>();
    final _nomeController = TextEditingController(text: isEditMode ? item['alimento'] : '');
    final _gramasController = TextEditingController(text: isEditMode ? item['gramas'].toString() : '');
    final _kcalController = TextEditingController(text: isEditMode ? item['calorias'].toString() : '');
    final _protController = TextEditingController(text: isEditMode ? item['proteinas'].toString() : '');
    final _carbController = TextEditingController(text: isEditMode ? item['carboidratos'].toString() : '');
    final _gordController = TextEditingController(text: isEditMode ? item['gorduras'].toString() : '');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditMode ? "Editar Alimento" : "Adicionar Alimento"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: "Alimento"), validator: (v) => v!.isEmpty ? "Obrigatório" : null),
                  TextFormField(controller: _gramasController, decoration: const InputDecoration(labelText: "Gramas (g)"), keyboardType: TextInputType.number),
                  TextFormField(controller: _kcalController, decoration: const InputDecoration(labelText: "Calorias (kcal)"), keyboardType: TextInputType.number),
                  TextFormField(controller: _protController, decoration: const InputDecoration(labelText: "Proteínas (g)"), keyboardType: TextInputType.number),
                  TextFormField(controller: _carbController, decoration: const InputDecoration(labelText: "Carboidratos (g)"), keyboardType: TextInputType.number),
                  TextFormField(controller: _gordController, decoration: const InputDecoration(labelText: "Gorduras (g)"), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            if (isEditMode)
              TextButton(
                onPressed: () {
                  _alimentosAnalisados.removeAt(index!);
                  _recalcularTotais();
                  Navigator.of(context).pop();
                },
                child: const Text("Deletar", style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final novoItem = {
                    'alimento': _nomeController.text,
                    'gramas': int.tryParse(_gramasController.text) ?? 0,
                    'calorias': int.tryParse(_kcalController.text) ?? 0,
                    'proteinas': int.tryParse(_protController.text) ?? 0,
                    'carboidratos': int.tryParse(_carbController.text) ?? 0,
                    'gorduras': int.tryParse(_gordController.text) ?? 0,
                  };
                  if (isEditMode) {
                    _alimentosAnalisados[index!] = novoItem;
                  } else {
                    _alimentosAnalisados.add(novoItem);
                  }
                  _recalcularTotais();
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
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
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _mostrarOpcoesEscolha,
                  child: Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                    child: _imagemSelecionada != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imagemSelecionada!, fit: BoxFit.cover))
                        : const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.grey)),
                  ),
                ),
                if (_isAnalysing)
                  Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
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

  Widget _buildListaAlimentos() {
    if (_isAnalysing) {
      return const Center(child: CircularProgressIndicator());
    }
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
                onTap: () {
                  _mostrarDialogoEdicao(item: alimento, index: index);
                },
              ),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          label: const Text("Adicionar Alimento", style: TextStyle(color: Colors.green)),
          onPressed: () {
            _mostrarDialogoEdicao();
          },
        ),
        const SizedBox(height: 10),
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