import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PedidosBartenderPage extends StatefulWidget {
  const PedidosBartenderPage({super.key});

  @override
  State<PedidosBartenderPage> createState() => _PedidosBartenderPageState();
}

class _PedidosBartenderPageState extends State<PedidosBartenderPage> {
  List<String> pedidosAnteriores = [];
  String? mesaSeleccionada;

  Stream<QuerySnapshot> obtenerPedidosPorEstado(String estado) {
    return FirebaseFirestore.instance
        .collection("pedidos")
        .where("estado", isEqualTo: estado)
        .orderBy("fecha", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pedidos en Tiempo Real")),
      body: Column(
        children: [
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("pedidos")
                  .orderBy("fecha", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final pedidos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final estado = data['estado'] ?? 'pendiente';
                  final mesa = data['nombreCliente']?.toString();
                  final activo = estado != 'entregado' && estado != 'cancelado';;
                  final coincideFiltro = mesaSeleccionada == null || mesaSeleccionada == mesa;
                  return activo && coincideFiltro;
                }).toList();

                final nuevos = pedidos.where((p) => !pedidosAnteriores.contains(p.id)).toList();
                if (nuevos.isNotEmpty) {
                  pedidosAnteriores = pedidos.map((e) => e.id).toList();
                }

                return ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final data = pedido.data() as Map<String, dynamic>;
                    final productos = data['productos'] as List;
                    final estado = data['estado'] ?? 'pendiente';
                    final nombres = productos.map((p) => "${p['cantidad']}x ${p['nombre']}").join(", ");
                    final observacion = data['observacion'] ?? '';
                    final mesa = data['nombreCliente'];
                    final total = data['total'] ?? 0;

                    Color colorEstado;
                    switch (estado) {
                      case "preparando":
                        colorEstado = Colors.orange;
                        break;
                      case "listo":
                        colorEstado = Colors.green;
                        guardarVenta(productos, total);
                        break;
                      default:
                        colorEstado = Colors.red;
                    }

                    return Card(
                      color: colorEstado.withOpacity(0.2),
                      child: ListTile(
                        title: Text("Cliente: $mesa"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombres),
                            if (observacion.isNotEmpty)
                              Text("📝 $observacion", style: const TextStyle(fontStyle: FontStyle.italic)),
                            Text("Estado: $estado", style: TextStyle(color: colorEstado))
                          ],
                        ),
                        trailing: _botonEstado(pedido.id, estado),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEstado(String docId, String estado) {
    List<Widget> botones = [];

    if (estado == "pendiente") {
      botones.add(ElevatedButton(
        onPressed: () => actualizarEstado(docId, "preparando"),
        child: const Text("Preparar"),
      ));
    } else if (estado == "preparando") {
      botones.add(ElevatedButton(
        onPressed: () => actualizarEstado(docId, "listo"),
        child: const Text("Listo"),
      ));
    } else if (estado == "listo") {
      botones.add(ElevatedButton(
        onPressed: () => actualizarEstado(docId, "entregado"),
        child: const Text("Entregado"),
      ));
    }

    if (estado != "entregado") {
      botones.add(const SizedBox(width: 8));
      botones.add(
        ElevatedButton(
          onPressed: () async {
            final confirmar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Cancelar pedido"),
                content: const Text("¿Estás seguro que deseas cancelar este pedido?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí")),
                ],
              ),
            );

            if (confirmar == true) {
              await actualizarEstado(docId, "cancelado");
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Cancelar"),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: botones);
  }


  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    await FirebaseFirestore.instance.collection("pedidos").doc(docId).update({
      "estado": nuevoEstado,
    });
  }

  Future<void> guardarVenta(List carrito, int total) async {
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
  }
}
