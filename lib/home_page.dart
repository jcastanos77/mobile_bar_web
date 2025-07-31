import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  bool? _esAdmin;
  String? fullName;
  final user = FirebaseAuth.instance.currentUser;

  Future<bool> esAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) return false;
    final data = doc.data();
    setState(() {
      fullName = data?['nombre'] + " " + data?['apellido'];
    });
    return data?['admin'] == true;
  }



  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      esAdmin(uid).then((valor) {
        setState(() {
          _esAdmin = valor;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¡Bienvenido, ${fullName ?? "usuario"}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tomar_pedidos');
              },
              child: const Text('Tomar pedidos'),
            ),
            const SizedBox(height: 20),
            if (_esAdmin == true)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/historial');
              },
              child: const Text('Historial de ventas'),
            ),
            const SizedBox(height: 20),
            if (_esAdmin == true)
              ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/agregar_producto');
              },
              child: const Text('Agregar producto'),
            ),
            const SizedBox(height: 20),
            if (_esAdmin == true)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registrar');
                },
                child: const Text('Registrar usuario'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/productos');
              },
              child: const Text('Ver productos'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pedidos_time_real');
              },
              child: const Text('Ver pedidos'),
            ),
          ],
        ),
      ),
    );
  }
}
