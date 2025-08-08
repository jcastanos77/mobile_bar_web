import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
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
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: () {
              context.pop();
            },
          ),
          backgroundColor: Colors.teal,
          title: const Text('Productos')),
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmarEliminacion(context, producto.id),
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
        onPressed: () => _mostrarDialogoAgregarProducto(context),
        child: const Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, String idProducto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Eliminar producto', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este producto?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('productos').doc(idProducto).delete();
              Navigator.pop(context);
            },
          ),
        ],
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

  Future<void> _mostrarDialogoAgregarProducto(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    bool activo = true;
    Uint8List? imagenSeleccionada;
    String? nombreArchivo;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                        onTap: () async {
                          if (kIsWeb) {
                            final bytes = await seleccionarImagenWeb();
                            if (bytes != null) {
                              setStateDialog(() {
                                imagenSeleccionada = bytes;
                                nombreArchivo = 'imagen_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              });
                            }
                          }else{
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              setStateDialog(() {
                                imagenSeleccionada = result.files.single.bytes;
                                nombreArchivo = result.files.single.name;
                              });
                            }
                          }
                        },
                        child: imagenSeleccionada != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imagenSeleccionada!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Seleccionar imagen',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
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
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Campo requerido' : null,
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
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Campo requerido' : null,
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
                      if (imagenSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selecciona una imagen')),
                        );
                        return;
                      }

                      final nombre = nombreController.text.trim();
                      final precio = double.tryParse(precioController.text.trim());

                      if (precio == null || precio <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un precio válido')),
                        );
                        return;
                      }

                      try {
                        final nombreImage = await subirImagenACloudinary(imagenSeleccionada!);

                        await FirebaseFirestore.instance.collection('productos').add({
                          'nombre': nombre,
                          'precio': precio,
                          'activo': activo,
                          'imagen': nombreImage,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto agregado exitosamente')),
                        );

                        Navigator.pop(context);
                      } catch (e, s) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ocurrió un error al guardar el producto')),
                        );
                      }
                    }
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Uint8List?> seleccionarImagenWeb() async {
    final completer = Completer<Uint8List?>();

    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..style.display = 'none';

    html.document.body!.append(input);

    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as Uint8List);
        input.remove();
      });
    });

    input.click();

    return completer.future;
  }

  Future<String?> subirImagenACloudinary(Uint8List imagenBytes) async {
    const cloudName = 'dawddzadq';
    const uploadPreset = 'mobile_bar_web';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imagenBytes,
        filename: 'imagen_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      print('Error al subir imagen: ${response.statusCode}');
      print(responseBody);
      return null;
    }
  }

}
