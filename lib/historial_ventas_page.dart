import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistorialVentasPage extends StatelessWidget {
  const HistorialVentasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Ventas")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .where('fecha', isGreaterThanOrEqualTo: inicioDelDia.toIso8601String())
            .where('fecha', isLessThan: finDelDia.toIso8601String())
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final ventas = snapshot.data!.docs;

          double totalDelDia = 0;
          for (var venta in ventas) {
            final data = venta.data() as Map<String, dynamic>;
            totalDelDia += (data['total'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text("Total vendido hoy: \$${totalDelDia.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: ventas.length,
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    final data = venta.data() as Map<String, dynamic>;

                    final productos = data['productos'] as List<dynamic>? ?? [];
                    final nombres = productos.map((p) => p['nombre']).join(", ");

                    return ListTile(
                      title: Text("Venta: \$${data['total'].toString()}"),
                      subtitle: Text("Productos: $nombres"),
                      trailing: Text(data['vendedorEmail'] ?? ""),
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
