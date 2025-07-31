import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_bar_web/historial_ventas_page.dart';
import 'package:mobile_bar_web/pedidos_page.dart';
import 'package:mobile_bar_web/registrar_usuario_page.dart';
import 'package:mobile_bar_web/registrar_venta_page.dart';
import 'package:mobile_bar_web/tomar_pedido_page.dart';

import 'agregar_producto_page.dart';
import 'home_page.dart';
import 'lista_productos_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA7USjJwmH8g2iQO5REJ_72dFOd1CJl0ZQ",
      authDomain: "mobilebarweb.firebaseapp.com",
      projectId: "mobilebarweb",
      storageBucket: "mobilebarweb.firebasestorage.app",
      messagingSenderId: "335910534181",
      appId: "1:335910534181:web:300a3b8a0837e0df4713cc",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Punto de Venta',
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              return HomePage();
            } else {
              return LoginPage();
            }
          },
        ),
      routes: {
        '/login': (_) => LoginPage(),
        '/home': (_) => const HomePage(),
        '/agregar_producto': (_) => const AgregarProductoPage(),
        '/registrar': (_) => const RegistrarUsuarioPage(),
        '/productos': (_) => const ListaProductosPage(),
        '/ventas': (_) => const RegistrarVentaPage(),
        '/historial': (_) => const HistorialVentasPage(),
        '/tomar_pedidos': (_) => const TomarPedidoPage(),
        '/pedidos_time_real': (_) => const PedidosBartenderPage(),

      }
    );
  }
}
