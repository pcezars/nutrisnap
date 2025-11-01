
import 'package:flutter/material.dart';

// 1. Importe o Firebase Core
import 'package:firebase_core/firebase_core.dart';

// 2. Importe o arquivo de opções gerado pelo FlutterFire
import 'firebase_options.dart';

// A "main" agora é assíncrona (async)
void main() async {
  // 3. Garante que o Flutter esteja pronto antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 5. Linha de teste para sabermos que funcionou!
  print("Firebase inicializado com sucesso!");

  // O resto do app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Vamos usar uma tela bem simples por enquanto
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NutriSnap - Conectado!'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            'Firebase Conectado com Sucesso!',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}