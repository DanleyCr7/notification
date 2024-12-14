import 'dart:convert';

import 'package:enable_notification/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa o Firebase em background\
  await Firebase.initializeApp();
  print('Mensagem recebida em segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final platform = const MethodChannel('com.example.silent_mode');
  bool isSilentMode = false;

  Future<String> getAccessToken() async {
    // Carregar o arquivo JSON da chave da conta de serviço
    String jsonKey = await rootBundle.loadString('assets/google-services.json');

    // Crie as credenciais a partir do arquivo JSON
    final credentials = ServiceAccountCredentials.fromJson(jsonKey);

    // Autenticar-se e obter o token de acesso
    final client = await clientViaServiceAccount(
        credentials, ['https://www.googleapis.com/auth/firebase.messaging']);
    // final authHeaders = await client.readHeaders();
    return '';
  }

  Future<void> sendNotification(String token, String title, String body) async {
    const url = 'https://fcm.googleapis.com/fcm/send';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=YOUR_SERVER_KEY' // Substitua pela chave do servidor FCM
    };

    final payload = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      print('Notificação enviada com sucesso');
    } else {
      print('Erro ao enviar notificação');
    }
  }

  Future<void> requestDoNotDisturbPermission() async {
    if (await Permission.accessNotificationPolicy.isDenied) {
      await Permission.accessNotificationPolicy.request();
    }
  }

  Future<void> setSilentMode(bool enable) async {
    try {
      await platform.invokeMethod('setSilentMode', {'enable': enable});
    } on PlatformException catch (e) {
      print("Erro ao definir modo silencioso: ${e.message}");
    }
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('Token FCM: $token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Aplicativo de desativar\nmodo silencioso',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            InkWell(
              onTap: requestDoNotDisturbPermission,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                ),
                child: const Text(
                  'Solicitar permissao',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            InkWell(
              onTap: () {
                setState(() {
                  isSilentMode = !isSilentMode;
                });
                setSilentMode(isSilentMode);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Ativar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
