class Producto {
  final String id;
  final String nombre;
  final double precio;
  final int stock;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
  });

  factory Producto.fromFirestore(String id, Map<String, dynamic> data) {
    return Producto(
      id: id,
      nombre: data['nombre'],
      precio: (data['precio'] as num).toDouble(),
      stock: data['stock'] ?? 0,
    );
  }
}
