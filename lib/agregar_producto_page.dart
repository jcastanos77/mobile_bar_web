import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final productos = snapshot.data!.docs;

          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final producto = productos[index];
              final data = producto.data() as Map<String, dynamic>;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: ListTile(
                  title: Text(
                    data['nombre'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '\$${(data['precio'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: data['activo'] ?? false,
                        onChanged: (val) {
                          FirebaseFirestore.instance
                              .collection('productos')
                              .doc(producto.id)
                              .update({'activo': val});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _editarProducto(context, producto.id, data),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregarProducto,
        child: const Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }

  void _editarProducto(BuildContext context, String id, Map<String, dynamic> data) {
    final nombreController = TextEditingController(text: data['nombre']);
    final precioController = TextEditingController(text: data['precio'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Editar producto', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precioController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Guardar', style: TextStyle(color: Colors.greenAccent)),
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final precio = double.tryParse(precioController.text.trim()) ?? 0.0;

              await FirebaseFirestore.instance.collection('productos').doc(id).update({
                'nombre': nombre,
                'precio': precio,
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoAgregarProducto() async {
    final _formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    bool activo = true;
    File? imagenSeleccionada;
    String? imageUrl;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> _seleccionarImagen() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setStateDialog(() {
                imagenSeleccionada = File(pickedFile.path);
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text('Agregar producto', style: TextStyle(color: Colors.white)),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _seleccionarImagen,
                      child: imagenSeleccionada != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(imagenSeleccionada!, height: 100),
                      )
                          : Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey[700],
                        alignment: Alignment.center,
                        child: const Text('Seleccionar imagen', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: precioController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    Row(
                      children: [
                        const Text('¿Activo?', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: activo,
                          onChanged: (val) => setStateDialog(() => activo = val),
                          activeColor: Colors.greenAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Guardar', style: TextStyle(color: Colors.greenAccent)),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final nombre = nombreController.text.trim();
                  final precio = double.tryParse(precioController.text.trim());

                  if (precio == null || precio <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa un precio válido')),
                    );
                    return;
                  }

                  if (imagenSeleccionada != null) {
                    final fileName = 'productos/${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final ref = FirebaseStorage.instance.ref().child(fileName);
                    await ref.putFile(imagenSeleccionada!);
                    imageUrl = await ref.getDownloadURL();
                  }

                  await FirebaseFirestore.instance.collection('productos').add({
                    'nombre': nombre,
                    'precio': precio,
                    'activo': activo,
                    'imagenUrl': imageUrl ?? '',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto agregado exitosamente')),
                  );

                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
      },
    );
  }
}
