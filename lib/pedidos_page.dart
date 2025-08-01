import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PedidosBartenderPage extends StatefulWidget {
  const PedidosBartenderPage({super.key});

  @override
  State<PedidosBartenderPage> createState() => _PedidosBartenderPageState();
}

class _PedidosBartenderPageState extends State<PedidosBartenderPage>
    with TickerProviderStateMixin {
  List<String> pedidosAnteriores = [];
  String? mesaSeleccionada;

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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedidos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final estado = data['estado'] ?? 'pendiente';
                  final mesa = data['nombreCliente']?.toString();
                  final activo = estado != 'entregado' && estado != 'cancelado';
                  final coincideFiltro =
                      mesaSeleccionada == null || mesaSeleccionada == mesa;
                  return activo && coincideFiltro;
                }).toList();

                final nuevos =
                pedidos.where((p) => !pedidosAnteriores.contains(p.id)).toList();
                if (nuevos.isNotEmpty) {
                  pedidosAnteriores = pedidos.map((e) => e.id).toList();
                }

                if (pedidos.isEmpty) {
                  return const Center(child: Text("No hay pedidos activos"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final data = pedido.data() as Map<String, dynamic>;
                    final productos = data['productos'] as List<dynamic>;
                    final estado = data['estado'] ?? 'pendiente';
                    final nombres =
                    productos.map((p) => "${p['cantidad']}x ${p['nombre']}").join(", ");
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
                        break;
                      default:
                        colorEstado = Colors.red;
                    }

                    return AnimatedPedidoCard(
                      key: ValueKey(pedido.id),
                      colorEstado: colorEstado,
                      mesa: mesa,
                      nombres: nombres,
                      observacion: observacion,
                      estado: estado,
                      total: total,
                      onActualizarEstado: (nuevoEstado) =>
                          actualizarEstado(pedido.id, nuevoEstado),
                      onCancelar: () => cancelarPedido(pedido.id),
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

  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    await FirebaseFirestore.instance.collection("pedidos").doc(docId).update({
      "estado": nuevoEstado,
    });

    if (nuevoEstado == "listo") {
      final doc =
      await FirebaseFirestore.instance.collection("pedidos").doc(docId).get();
      final data = doc.data()!;
      final productos = data['productos'] as List<dynamic>;
      final total = data['total'] ?? 0;
      await guardarVenta(productos, total);
    }
  }

  Future<void> cancelarPedido(String docId) async {
    await FirebaseFirestore.instance.collection("pedidos").doc(docId).update({
      "estado": "cancelado",
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada')),
      );
    }
  }
}

class AnimatedPedidoCard extends StatefulWidget {
  final Color colorEstado;
  final String? mesa;
  final String nombres;
  final String observacion;
  final String estado;
  final int total;
  final Function(String nuevoEstado) onActualizarEstado;
  final VoidCallback onCancelar;

  const AnimatedPedidoCard({
    Key? key,
    required this.colorEstado,
    required this.mesa,
    required this.nombres,
    required this.observacion,
    required this.estado,
    required this.total,
    required this.onActualizarEstado,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<AnimatedPedidoCard> createState() => _AnimatedPedidoCardState();
}

class _AnimatedPedidoCardState extends State<AnimatedPedidoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEstadoBotones() {
    List<Widget> botones = [];

    if (widget.estado == "pendiente") {
      botones.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            key: const ValueKey('preparar'),
            onPressed: () => widget.onActualizarEstado("preparando"),
            child: const Text("Preparar"),
          ),
        ),
      );
    } else if (widget.estado == "preparando") {
      botones.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            key: const ValueKey('listo'),
            onPressed: () => widget.onActualizarEstado("listo"),
            child: const Text("Listo"),
          ),
        ),
      );
    } else if (widget.estado == "listo") {
      botones.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            key: const ValueKey('entregado'),
            onPressed: () => widget.onActualizarEstado("entregado"),
            child: const Text("Entregado"),
          ),
        ),
      );
    }

    if (widget.estado != "entregado" && widget.estado != "cancelado") {
      botones.add(const SizedBox(width: 8));
      botones.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            key: const ValueKey('cancelar'),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cancelar pedido"),
                  content: const Text("¿Estás seguro que deseas cancelar este pedido?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("No")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Sí")),
                  ],
                ),
              );
              if (confirmar == true) {
                widget.onCancelar();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cancelar"),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: botones);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: widget.colorEstado.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cliente: ${widget.mesa ?? 'Desconocido'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(widget.nombres),
                if (widget.observacion.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.note_alt_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.observacion,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  "Estado: ${widget.estado}",
                  style:
                  TextStyle(color: widget.colorEstado, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildEstadoBotones(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
