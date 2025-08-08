import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_bar_web/historial_ventas_page.dart';
import 'package:mobile_bar_web/pedidos_page.dart';
import 'package:mobile_bar_web/registrar_usuario_page.dart';
import 'package:mobile_bar_web/tomar_pedido_page.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'agregar_producto_page.dart';
import 'home_page.dart';
import 'login_page.dart';

void main() async {
  setUrlStrategy(PathUrlStrategy());
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  final GoRouter router = GoRouter(
    redirect: (context, state) {

      final user = FirebaseAuth.instance.currentUser;
      final loggingIn = state.uri.path == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/tomar_pedidos',
        builder: (context, state) => const TomarPedidoScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/productos',
        builder: (context, state) => const AgregarProductoPage(),
      ),
      GoRoute(
        path: '/registrar',
        builder: (context, state) => const RegistrarUsuarioPage(),
      ),
      GoRoute(
        path: '/historial',
        builder: (context, state) => const HistorialVentasPage(),
      ),
      GoRoute(
        path: '/tomar_pedidos',
        builder: (context, state) => const TomarPedidoScreen(),
      ),
      GoRoute(
        path: '/pedidos_time_real',
        builder: (context, state) => const PedidosBartenderPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
            elevation: 0,
            centerTitle: true,
          ),
          colorScheme: ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.deepPurpleAccent,
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        )
    );
  }
}
