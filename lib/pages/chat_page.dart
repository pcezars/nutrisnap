// lib/pages/chat_page.dart
import 'package:flutter/material.dart';
// NOVO: Imports do Gemini
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_key.dart'; // A nossa chave de API
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  // NOVO: Variáveis para receber o contexto
  final int metaCalorias;
  final int metaProteinas;
  final int metaCarboidratos;
  final int metaGorduras;
  final int consumidoCalorias;
  final int consumidoProteinas;
  final int consumidoCarboidratos;
  final int consumidoGorduras;

  const ChatPage({
    super.key,
    required this.metaCalorias,
    required this.metaProteinas,
    required this.metaCarboidratos,
    required this.metaGorduras,
    required this.consumidoCalorias,
    required this.consumidoProteinas,
    required this.consumidoCarboidratos,
    required this.consumidoGorduras,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  // NOVO: Instância do Modelo de Texto
  late final GenerativeModel _model;
  // NOVO: A sessão de chat que guarda o histórico
  late final ChatSession _chatSession;

  final List<Map<String, String>> _mensagens = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // NOVO: Inicializa o modelo de texto
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // O modelo de texto
      apiKey: geminiApiKey,
    );

    // NOVO: Cria o "Prompt de Sistema" com o contexto do utilizador
    final String promptDeSistema = 
      "Você é o 'Nutri Coach', um assistente nutricional amigável e motivador. "
      "O utilizador está a usar a app NutriSnap e tem as seguintes metas diárias: "
      "Meta de Calorias: ${widget.metaCalorias} kcal, "
      "Meta de Proteínas: ${widget.metaProteinas}g, "
      "Meta de Carboidratos: ${widget.metaCarboidratos}g, "
      "Meta de Gorduras: ${widget.metaGorduras}g. "
      "\n"
      "Até agora, hoje, o utilizador já consumiu: "
      "Consumido Calorias: ${widget.consumidoCalorias} kcal, "
      "Consumido Proteínas: ${widget.consumidoProteinas}g, "
      "Consumido Carboidratos: ${widget.consumidoCarboidratos}g, "
      "Consumido Gorduras: ${widget.consumidoGorduras}g. "
      "\n"
      "Responda às perguntas do utilizador com base neste contexto. Seja breve, positivo e dê sugestões práticas. "
      "Comece com uma saudação.";

    // NOVO: Inicia a sessão de chat com o prompt
    _chatSession = _model.startChat(
      history: [
        // O Gemini entende o "model" como a IA e o "user" como o utilizador.
        // O "model" dá a saudação inicial.
        Content.model([
          TextPart("Olá! Eu sou o seu assistente nutricional. "
          "Já analisei as suas metas e o seu consumo de hoje. "
          "Como posso ajudar?")
        ])
      ],
      // NOTA: Vamos enviar o "promptDeSistema" junto com a primeira mensagem do utilizador
      // para garantir que o contexto seja aplicado.
    );
    
    // Adiciona a mensagem inicial da IA à nossa UI
    _mensagens.add({
      'role': 'ia',
      'texto': 'Olá! Eu sou o seu assistente nutricional. Já analisei as suas metas e o seu consumo de hoje. Como posso ajudar?'
    });
  }

  // MODIFICADO: Função de enviar agora chama o Gemini
  // lib/pages/chat_page.dart

  // MODIFICADO: A função de enviar agora usa "Streaming"
  Future<void> _enviarMensagem() async {
    final mensagemUsuario = _textController.text;
    if (mensagemUsuario.isEmpty) return;

    setState(() {
      _isLoading = true; // Desabilita o botão de enviar
      _mensagens.add({'role': 'user', 'texto': mensagemUsuario});
      _textController.clear();
    });
    
    _scrollParaFim();

    // 1. Constrói o contexto (igual a antes)
    final String contextoCompleto = 
        "Contexto do Utilizador: "
        "Meta Diária: ${widget.metaCalorias} kcal (P: ${widget.metaProteinas}g, C: ${widget.metaCarboidratos}g, G: ${widget.metaGorduras}g). "
        "Consumido Hoje: ${widget.consumidoCalorias} kcal (P: ${widget.consumidoProteinas}g, C: ${widget.consumidoCarboidratos}g, G: ${widget.consumidoGorduras}g). "
        "Pergunta do Utilizador: $mensagemUsuario"
        "\n\n"
        "**INSTRUÇÕES IMPORTANTES DE RESPOSTA:**"
        "1. Responda como um 'coach' num chat. Use parágrafos curtos e emojis ocasionais (ex: 💪, 🥦, 👍)."
        "2. Use formatação Markdown (como **negrito** para títulos) para organizar a resposta."
        "3. Mantenha a resposta o mais breve e prática possível.";
        
    // 2. NOVO: Adiciona uma "bolha de chat" vazia para a IA
    setState(() {
      _mensagens.add({'role': 'ia', 'texto': ''});
    });
    // Pega o índice da mensagem que acabámos de adicionar
    final int iaMessageIndex = _mensagens.length - 1;

    try {
      // 3. NOVO: Chama o 'generateContentStream'
      final responseStream = _model.generateContentStream([
        Content.text(contextoCompleto)
      ]);

      // 4. NOVO: Ouve o "Stream" de pedaços (chunks)
      await for (final chunk in responseStream) {
        final chunkText = chunk.text;
        if (chunkText != null) {
          setState(() {
            // Anexa o novo pedaço de texto à mensagem existente
            _mensagens[iaMessageIndex]['texto'] = 
                _mensagens[iaMessageIndex]['texto']! + chunkText;
          });
          _scrollParaFim(); // Faz scroll a cada novo pedaço
        }
      }
      
      // 5. NOVO: O Stream terminou, reativa o botão
      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao chamar o Gemini (Stream): $e");
      setState(() {
        _isLoading = false;
        _mensagens[iaMessageIndex]['texto'] = 'Ocorreu um erro ao contactar a IA. Tente mais tarde.';
      });
    }
  }
  
  void _scrollParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // (A UI (build) continua 100% igual à da fase simulada)
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutri Coach IA"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _mensagens.length,
              itemBuilder: (context, index) {
                final msg = _mensagens[index];
                final bool isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: MarkdownBody(
                      data: msg['texto']!,
                      selectable: true,),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Pergunte algo...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  icon: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}