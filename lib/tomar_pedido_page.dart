import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TomarPedidoPage extends StatefulWidget {
  const TomarPedidoPage({super.key});

  @override
  State<TomarPedidoPage> createState() => _TomarPedidoPageState();
}

class _TomarPedidoPageState extends State<TomarPedidoPage> {
  final TextEditingController nombreClienteController = TextEditingController();
  List<Map<String, dynamic>> productosDisponibles = [];
  Map<String, int> carrito = {};
  bool loading = true;
  double total = 0;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  void agregarProducto(String nombre) {
    setState(() {
      carrito[nombre] = (carrito[nombre] ?? 0) + 1;
    });
  }

  Future<void> cargarProductos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("productos")
        .get();

    setState(() {
      productosDisponibles = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "nombre": data["nombre"],
          "precio": data["precio"]
        };
      }).toList();
      loading = false;
    });
  }

  Future<void> enviarPedido() async {
    if (carrito.isEmpty || nombreClienteController.text.isEmpty) return;

    final productos = carrito.entries.map((e) {
      final info = productosDisponibles.firstWhere((p) => p["nombre"] == e.key);
      total += info['precio'];
      return {
        "nombre": e.key,
        "cantidad": e.value,
        "precio": info["precio"]
      };
    }).toList();

    await FirebaseFirestore.instance.collection("pedidos").add({
      "nombreCliente": nombreClienteController.text,
      "productos": productos,
      "estado": "pendiente",
      "fecha": DateTime.now(),
      "total": total,
      "usuarioId": FirebaseAuth.instance.currentUser?.uid
    });

    setState(() {
      carrito.clear();
      nombreClienteController.clear();
      total = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pedido enviado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Pedido")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombreClienteController,
              decoration: const InputDecoration(labelText: "Nombre cliente"),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            const Text(
                "Productos", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: productosDisponibles.map((producto) {
                  return ListTile(
                    title: Text(
                        "${producto["nombre"]} - \$${producto["precio"]}"),
                    trailing: ElevatedButton(
                      onPressed: () => agregarProducto(producto["nombre"]),
                      child: const Text("Agregar"),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
                "Carrito", style: TextStyle(fontWeight: FontWeight.bold)),

            if (carrito.isEmpty)
              const Text("No hay productos en el carrito"),
            ...carrito.entries.map((e) {
              final producto = productosDisponibles.firstWhere((
                  p) => p["nombre"] == e.key);
              final subtotal = e.value * producto["precio"];
              return ListTile(
                title: Text("${e.key} x${e.value}"),
                subtitle: Text("Subtotal: \$${subtotal.toStringAsFixed(2)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => quitarProducto(e.key),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            Text(
              "Total: \$${calcularTotal().toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            ElevatedButton(
              onPressed: enviarPedido,
              child: const Text("Enviar Pedido"),
            ),
          ],
        ),
      ),
    );
  }

  double calcularTotal() {
    double total = 0;
    for (var e in carrito.entries) {
      final producto = productosDisponibles.firstWhere((p) => p["nombre"] == e.key);
      total += e.value * (producto["precio"] ?? 0);
    }
    return total;
  }


  void quitarProducto(String nombre) {
    setState(() {
      if (carrito.containsKey(nombre)) {
        if (carrito[nombre]! > 1) {
          carrito[nombre] = carrito[nombre]! - 1;
        } else {
          carrito.remove(nombre);
        }
      }
    });
  }
}
