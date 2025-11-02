import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

// NOVO: Imports do Firebase
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  File? _imagemSelecionada;
  final TextEditingController _alimentosController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // NOVO: Variável para controlar o estado de loading
  bool _isLoading = false;

  // NOVO: Função principal para salvar
  Future<void> _salvarRefeicao() async {
    // 1. Validar se os campos estão preenchidos
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
      _isLoading = true; // Inicia o loading
    });

    try {
      // 2. Pegar o usuário logado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Segurança (não deve acontecer)

      // 3. Criar um caminho único para a imagem no Storage
      // ex: refeicoes/ID_DO_USUARIO/timestamp_da_imagem.jpg
      final String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference refStorage = FirebaseStorage.instance
          .ref()
          .child('refeicoes')
          .child(user.uid)
          .child('$nomeArquivo.jpg');

      // 4. Fazer o upload do arquivo da imagem
      await refStorage.putFile(_imagemSelecionada!);

      // 5. Pegar a URL de download da imagem que acabamos de subir
      final String downloadUrl = await refStorage.getDownloadURL();

      // 6. Salvar os dados no Banco de Dados (Firestore)
      await FirebaseFirestore.instance.collection('refeicoes').add({
        'userId': user.uid,
        'emailUsuario': user.email,
        'alimentos': _alimentosController.text,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(), // Pega a hora do servidor
      });

      // 7. Sucesso! Voltar para a Home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refeição salva com sucesso!")),
        );
        Navigator.of(context).pop(); // Volta para a home_page
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
          _isLoading = false; // Termina o loading
        });
      }
    }
  }

  // (O resto das funções _mostrarOpcoesEscolha e _pegarImagem continuam iguais)
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

  Future<void> _pegarImagem(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(source: source);
      if (foto != null) {
        setState(() {
          _imagemSelecionada = File(foto.path);
        });
      }
    } catch (e) {
      print("Erro ao pegar imagem: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Nova Refeição"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 20),

            TextField(
              controller: _alimentosController,
              decoration: const InputDecoration(
                labelText: "Alimentos (ex: Arroz, Feijão, Bife)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // NOVO: Botão com lógica de loading
            ElevatedButton(
              // Se estiver carregando (isLoading), desabilita o botão (onPressed = null)
              onPressed: _isLoading ? null : _salvarRefeicao,
              child: _isLoading
                  ? const CircularProgressIndicator( // Mostra um "loading"
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