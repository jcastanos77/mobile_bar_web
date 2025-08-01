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
  final TextEditingController observacionController = TextEditingController();
  List<Map<String, dynamic>> productosDisponibles = [];
  Map<String, int> carrito = {};
  bool loading = true;

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

  Future<void> cargarProductos() async {
    final snapshot = await FirebaseFirestore.instance.collection("productos").get();

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

  double calcularTotal() {
    double total = 0;
    for (var e in carrito.entries) {
      final producto = productosDisponibles.firstWhere((p) => p["nombre"] == e.key);
      total += e.value * (producto["precio"] ?? 0);
    }
    return total;
  }

  Future<void> enviarPedido() async {
    if (carrito.isEmpty || nombreClienteController.text.isEmpty) return;

    final productos = carrito.entries.map((e) {
      final info = productosDisponibles.firstWhere((p) => p["nombre"] == e.key);
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
      "total": calcularTotal(),
      "usuarioId": FirebaseAuth.instance.currentUser?.uid,
      "observacion": observacionController.text.trim(),
    });

    setState(() {
      carrito.clear();
      nombreClienteController.clear();
      observacionController.clear();
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente y observación
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: Colors.white),
                      controller: nombreClienteController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del cliente",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: TextStyle(color: Colors.white),
                      controller: observacionController,
                      decoration: const InputDecoration(
                        labelText: "Observaciones",
                        hintText: "Ej: sin hielo, sin alcohol...",
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Productos disponibles
            const Text("Productos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 10),
            ...productosDisponibles.map((producto) {
              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: producto["imagenUrl"] != null
                        ? Image.network(
                      producto["imagenUrl"],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white38),
                    )
                        : const Icon(Icons.image_not_supported, color: Colors.white38),
                  ),
                  title: Text(producto["nombre"], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("\$${producto["precio"]}", style: const TextStyle(color: Colors.white60)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                    onPressed: () => agregarProducto(producto["nombre"]),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Carrito
            const Text("Carrito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            if (carrito.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No hay productos en el carrito", style: TextStyle(color: Colors.white54)),
              ),
            ...carrito.entries.map((e) {
              final producto = productosDisponibles.firstWhere((p) => p["nombre"] == e.key);
              final subtotal = e.value * producto["precio"];
              return ListTile(
                title: Text("${e.key} x${e.value}", style: const TextStyle(color: Colors.white)),
                subtitle: Text("Subtotal: \$${subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white60)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => quitarProducto(e.key),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Total y botón enviar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: \$${calcularTotal().toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  onPressed: enviarPedido,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.tealAccent[700],
                    foregroundColor: Colors.black,
                  ),
                  label: const Text("Enviar Pedido"),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF121212),
    );
  }
}
