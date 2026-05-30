import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// ============================================================
// MAIN.DART
//   1. Inicializar o Supabase (banco de dados + autenticação)
//   2. Inicializar o formato de datas em português
//   3. Decidir qual tela mostrar (login ou home)
// ============================================================

Future<void> main() async {
  // Garante que o Flutter esteja pronto antes de fazer qualquer coisa
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa as datas no formato pt_BR (ex: "28/05/2025")
  await initializeDateFormatting('pt_BR', null);

  // Conecta ao Supabase com as chaves do projeto
  await Supabase.initialize(
    url: 'https://ircvhmrmolirbwazavpa.supabase.co',   // URL do projeto
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyY3ZobXJtb2xpcmJ3YXphdnBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5ODQ4ODcsImV4cCI6MjA5NTU2MDg4N30.7o341HrOw-T9N4JN6hiOWex4LZHU1Shi74xzDZKymlI',                      // chave pública (anon)
  );

  runApp(const CicloApp());
}

// ============================================================
// CICLOAPP — Widget raiz do aplicativo
//
// Define o tema visual e a tela inicial.
// Se o usuário já estiver logado, vai direto para HomeScreen.
// Caso contrário, mostra a LoginScreen.
// ============================================================
class CicloApp extends StatelessWidget {
  const CicloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Ciclo',
      debugShowCheckedModeBanner: false,

      // ── CONFIGURAÇÃO DE LOCALIZAÇÃO ─────────────────────
      // Isso diz ao Flutter para traduzir calendários e componentes para PT-BR
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // ── Tema do aplicativo ─────────────────────────────
      // Para mudar a cor principal do app, altere o seedColor abaixo
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE57697), // rosa
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // ── Tela inicial ───────────────────────────────────
      // Verifica se há uma sessão ativa no Supabase.
      // currentSession != null → usuário já logado → vai para Home
      // currentSession == null → usuário deslogado  → vai para Login
      home: Supabase.instance.client.auth.currentSession != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}