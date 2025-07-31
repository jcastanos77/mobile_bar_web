import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistrarVentaPage extends StatefulWidget {
  const RegistrarVentaPage({Key? key}) : super(key: key);

  @override
  State<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends State<RegistrarVentaPage> {
  List<Map<String, dynamic>> carrito = [];
  double total = 0;

  void agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      carrito.add({
        'id': producto['id'],
        'nombre': producto['nombre'],
        'cantidad': 1,
        'precioUnitario': producto['precio']
      });
      total += producto['precio'];
    });
  }

  Future<void> guardarVenta() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection('ventas').add({
      'productos': carrito,
      'total': total,
      'fecha': DateTime.now().toIso8601String(),
      'vendedorId': user.uid,
      'vendedorEmail': user.email
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Venta registrada'),
    ));

    setState(() {
      carrito.clear();
      total = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar venta")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final productos = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;
                    data['id'] = producto.id;

                    return ListTile(
                      title: Text(data['nombre']),
                      subtitle: Text("\$${data['precio']}"),
                      trailing: ElevatedButton(
                        child: Text("Agregar"),
                        onPressed: () => agregarProducto(data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Text("Total: \$${total.toStringAsFixed(2)}"),
          ElevatedButton(onPressed: guardarVenta, child: Text("Guardar venta")),
        ],
      ),
    );
  }
}
