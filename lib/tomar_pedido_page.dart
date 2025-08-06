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
  bool mostrarCarrito = false;

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
       await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Completa todos los campos"),
          content: Text("Los datos estan incompletos"),
          actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Aceptar")),
          ],
        ),
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
        "nombreCliente": nombreClienteController.text.trim(),
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
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar pedido: \$e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  void mostrarDetalleCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[800],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el modal
                    },
                  ),
                ],
              ),
              const Text("Tu Pedido", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
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
            ...carrito.entries.expand((entry) {
          final producto = productosDisponibles.firstWhere(
                (p) => p["id"] == entry.key,
            orElse:() => <String, dynamic>{},
          );

          if (producto == null) return [];

          return [
            ListTile(
              title: Text(producto["nombre"], style: const TextStyle(color: Colors.white)),
              subtitle: Text("Cantidad: ${entry.value}", style: const TextStyle(color: Colors.white70)),
              trailing: Text(
                "\$${(producto["precio"] * entry.value).toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white),
              ),
            )
          ];
        }),
              const SizedBox(height: 8),
              Text("Total: \$${calcularTotal().toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: enviarPedido,
                  icon: const Icon(Icons.send),
                  label: const Text("Enviar Pedido"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text("Productos Disponibles", style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double itemWidth = 160;

                        int crossAxisCount = (constraints.maxWidth / itemWidth).floor();

                        if (crossAxisCount < 2) crossAxisCount = 2;

                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: productosDisponibles.length,
                          itemBuilder: (_, index) {
                            final producto = productosDisponibles[index];
                            return Card(
                              clipBehavior: Clip.hardEdge,
                              color: Colors.grey[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Imagen
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: producto["imagen"] != null
                                          ? Image.network(
                                        producto["imagen"],
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        height: 100,
                                        width: double.infinity,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.image_not_supported, color: Colors.white54),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      producto["nombre"] ?? "",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Precio: \$${producto["precio"]}",
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 5),
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle, color: Colors.tealAccent),
                                              onPressed: () {
                                                setState(() {
                                                  final current = carrito[producto["id"]];
                                                  if (current == 1) {
                                                    carrito.remove(producto["id"]);
                                                  } else {
                                                    carrito[producto["id"]] = (current! - 1).toInt();
                                                  }
                                                });
                                              },
                                            ),
                                            CircleAvatar(
                                              backgroundColor: Colors.tealAccent,
                                              radius: 12,
                                              child: Text(
                                                carrito[producto["id"]].toString() == "null" ? "0" : carrito[producto["id"]].toString(),
                                                style: const TextStyle(fontSize: 12, color: Colors.black),
                                              ),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                                            onPressed: () {
                                              setState(() {
                                                carrito[producto["id"]] = (carrito[producto["id"]] ?? 0) + 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
           const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: carrito.isEmpty ? null : FloatingActionButton.extended(
        onPressed: mostrarDetalleCarrito,
        icon: const Icon(Icons.shopping_cart, color: Colors.white,),
        label: Text('${carrito.values.reduce((a, b) => a + b)} productos', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
