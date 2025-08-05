import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TomarPedidoScreen extends StatefulWidget {
  const TomarPedidoScreen({super.key});

  @override
  State<TomarPedidoScreen> createState() => _TomarPedidoScreenState();
}

class _TomarPedidoScreenState extends State<TomarPedidoScreen> {
  final TextEditingController nombreClienteController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  List<Map<String, dynamic>> productosDisponibles = [];
  final user = FirebaseAuth.instance.currentUser;
  Map<String, int> carrito = {};
  bool cargando = false;
  String? fullName;

  @override
  void initState() {
    super.initState();
    cargarProductos();
    nameMesero(user!.uid);
  }

  Future<void> cargarProductos() async {
    final snapshot = await FirebaseFirestore.instance.collection("productos").get();
    setState(() {
      productosDisponibles = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();
    });
  }

  void agregarProducto(String id) {
    setState(() {
      carrito[id] = (carrito[id] ?? 0) + 1;
    });
  }

  void quitarProducto(String id) {
    setState(() {
      if (carrito.containsKey(id)) {
        if (carrito[id]! > 1) {
          carrito[id] = carrito[id]! - 1;
        } else {
          carrito.remove(id);
        }
      }
    });
  }

  Future<bool> nameMesero(String uid) async {
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

  double calcularTotal() {
    double total = 0;
    for (var e in carrito.entries) {
      final producto = productosDisponibles.firstWhere((p) => p["id"] == e.key);
      total += e.value * (producto["precio"] ?? 0);
    }
    return total;
  }

  Future<void> enviarPedido() async {
    if (carrito.isEmpty || nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Confirmar pedido?"),
        content: Text("Total a pagar: \$${calcularTotal().toStringAsFixed(2)}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirmar")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => cargando = true);

    try {
      final productos = carrito.entries.map((entry) {
        final producto = productosDisponibles.firstWhere((p) => p["id"] == entry.key);
        return {
          "nombre": producto["nombre"],
          "cantidad": entry.value,
          "precio": producto["precio"],
        };
      }).toList();

      await FirebaseFirestore.instance.collection("pedidos").add({
        "cliente": nombreClienteController.text.trim(),
        "productos": productos,
        "observaciones": observacionesController.text.trim(),
        "estado": "pendiente",
        "fecha": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
        "timestamp": FieldValue.serverTimestamp(),
        "total": calcularTotal(),
        "mesero": fullName,
      });

      setState(() {
        carrito.clear();
        nombreClienteController.clear();
        observacionesController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido enviado correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar pedido: \$e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Tomar Pedido"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Productos Disponibles", style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: productosDisponibles.length,
                      itemBuilder: (_, index) {
                        final producto = productosDisponibles[index];
                        return Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Imagen del producto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: producto["imagen"] != null
                                      ? Image.network(
                                    producto["imagen"],
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    height: 60,
                                    width: 60,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.image_not_supported, color: Colors.white54),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Nombre y precio
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto["nombre"] ?? "",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Precio: \$${producto["precio"]}",
                                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botón + contador
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (carrito[producto["id"]] != null)
                                      CircleAvatar(
                                        backgroundColor: Colors.tealAccent,
                                        radius: 12,
                                        child: Text(
                                          carrito[producto["id"]].toString(),
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                                      onPressed: () => agregarProducto(producto["id"]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Carrito", style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: carrito.entries.map((entry) {
                        final producto = productosDisponibles.firstWhere((p) => p["id"] == entry.key);
                        return ListTile(
                          title: Text(producto["nombre"] ?? "", style: const TextStyle(color: Colors.white)),
                          subtitle: Text("Cantidad: ${entry.value}  x  \$${producto["precio"]}", style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                            onPressed: () => quitarProducto(entry.key),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  TextField(
                    controller: nombreClienteController,
                    style: TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Nombre del cliente"),
                  ),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    controller: observacionesController,
                    decoration: const InputDecoration(labelText: "Observaciones"),
                  ),
                  const SizedBox(height: 8),
                  Text("Total: \$${calcularTotal().toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: enviarPedido,
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar Pedido"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
