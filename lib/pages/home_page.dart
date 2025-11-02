import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Importar o Firestore
import '../components/refeicao_card.dart'; // 2. Importar nosso Card
import 'registro_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 3. Pegar o usuário atual
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void irParaPaginaRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriSnap Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
          )
        ],
      ),
      
      // 4. Substituir o body por um StreamBuilder
      body: StreamBuilder<QuerySnapshot>(
        // 5. O "Stream": Ouvir a coleção 'refeicoes'
        stream: FirebaseFirestore.instance
            .collection('refeicoes')
            // 6. Onde o 'userId' for igual ao ID do usuário logado
            .where('userId', isEqualTo: currentUser?.uid)
            // 7. Ordenar pelas mais recentes primeiro
            .orderBy('timestamp', descending: true) 
            .snapshots(), // "Tire uma foto" (snapshot) do banco toda vez que ele mudar
        
        builder: (context, snapshot) {
          // 8. Se estiver carregando, mostre um loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 9. Se der erro
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          // 10. Se não tiver dados (nenhuma refeição salva)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma refeição registrada.\nClique no '+' para adicionar uma!",
                textAlign: TextAlign.center,
              ),
            );
          }

          // 11. Se tiver dados, mostre a lista!
          final List<DocumentSnapshot> documentos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              // Pegar os dados do documento
              final Map<String, dynamic> data =
                  documentos[index].data() as Map<String, dynamic>;
              
              // Converter o Timestamp do Firebase para DateTime do Dart
              final Timestamp timestamp = data['timestamp'];
              final DateTime dataRefeicao = timestamp.toDate();

              // Retornar o nosso Card customizado
              return RefeicaoCard(
                imageUrl: data['imageUrl'],
                alimentos: data['alimentos'],
                timestamp: dataRefeicao,
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: irParaPaginaRegistro,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_a_photo),
        tooltip: "Registrar Refeição",
      ),
    );
  }
}