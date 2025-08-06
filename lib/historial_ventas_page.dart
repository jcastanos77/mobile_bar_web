import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistorialVentasPage extends StatelessWidget {
  const HistorialVentasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(

          title: const Text("Historial de Ventas")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .where('fecha', isGreaterThanOrEqualTo: inicioDelDia.toIso8601String())
            .where('fecha', isLessThan: finDelDia.toIso8601String())
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ventas = snapshot.data!.docs;

          if (ventas.isEmpty) {
            return const Center(
              child: Text(
                'No hay ventas registradas hoy.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          double totalDelDia = 0;
          for (var venta in ventas) {
            final data = venta.data() as Map<String, dynamic>;
            totalDelDia += (data['total'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                color: Colors.blue.shade900,
                child: Text(
                  "Total vendido hoy: \$${totalDelDia.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ventas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    final data = venta.data() as Map<String, dynamic>;
                    final productos = data['productos'] as List<dynamic>? ?? [];

                    final nombresConCantidad = productos.map((p) {
                      final cantidad = p['cantidad'] ?? 1;
                      final nombre = p['nombre'] ?? '';
                      return "$cantidad x $nombre";
                    }).join(", ");

                    final fechaVenta = DateTime.tryParse(data['fecha'] ?? '') ?? hoy;

                    return Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Venta: \$${(data['total'] ?? 0).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Productos: $nombresConCantidad",
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      data['mesero'] ?? 'Sin mesero',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Text(
                                  formatoFecha.format(fechaVenta),
                                  style: const TextStyle(color: Colors.grey),
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
          );
        },
      ),
    );
  }
}
