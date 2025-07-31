import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Productos.dart';

class ListaProductosPage extends StatefulWidget {
  const ListaProductosPage({super.key});

  @override
  State<ListaProductosPage> createState() => _ListaProductosPageState();
}

class _ListaProductosPageState extends State<ListaProductosPage> {
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _productosFuture = obtenerProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos disponibles')),
      body: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final productos = snapshot.data ?? [];

          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos registrados'));
          }

          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                title: Text(producto.nombre),
                subtitle: Text('\$${producto.precio.toStringAsFixed(2)} — Stock: ${producto.stock}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Producto>> obtenerProductos() async {
    final snapshot = await FirebaseFirestore.instance.collection('productos').get();

    return snapshot.docs.map((doc) {
      return Producto.fromFirestore(doc.id, doc.data());
    }).toList();
  }

}
