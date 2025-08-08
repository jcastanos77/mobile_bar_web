import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _esAdmin;
  String? fullName;
  final user = FirebaseAuth.instance.currentUser;

  int ventasHoy = 0;
  int pedidosActivos = 0;
  int totalProductos = 0;

  Future<bool> esAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

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
    final uid = user?.uid;

    if (uid != null) {
      esAdmin(uid).then((valor) {
        setState(() => _esAdmin = valor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otro Trago Mobile Bar'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${fullName ?? "usuario"}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildCardButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Tomar pedidos',
                          onPressed: () =>
                              context.go('/tomar_pedidos')
                        ),
                        _buildCardButton(
                          icon: Icons.local_bar,
                          label: 'Ver pedidos',
                          onPressed: () => context.go('/pedidos_time_real')
                        ),
                        if (_esAdmin == true)
                          _buildCardButton(
                            icon: Icons.history,
                            label: 'Historial ventas',
                            onPressed: () => context.go('/historial')
                          ),
                        if (_esAdmin == true)
                          _buildCardButton(
                            icon: Icons.add_box,
                            label: 'Agregar producto',
                            onPressed: () => context.go('/productos')
                          ),
                        if (_esAdmin == true)
                          _buildCardButton(
                            icon: Icons.person_add,
                            label: 'Registrar usuario',
                            onPressed: () => context.go('/registrar')
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.tealAccent),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}