import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarUsuarioPage extends StatefulWidget {
  const RegistrarUsuarioPage({super.key});

  @override
  State<RegistrarUsuarioPage> createState() => _RegistrarUsuarioPageState();
}

class _RegistrarUsuarioPageState extends State<RegistrarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  bool _esAdmin = false;
  bool _cargando = false;

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Guardar datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'admin': _esAdmin,
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario registrado exitosamente')),
      );

      _emailController.clear();
      _passwordController.clear();
      _apellidoController.clear();
      _nombreController.clear();

      setState(() {
        _esAdmin = false;
        _cargando = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text('Registrar nuevo usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) =>
                value != null && value.contains('@') ? null : 'Correo inválido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value != null && value.length >= 3
                    ? null
                    : 'Mínimo 3 caracteres',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) => value != null && value.length >= 3
                    ? null
                    : 'Mínimo 3 caracteres',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('¿Es administrador?'),
                  Switch(
                    value: _esAdmin,
                    onChanged: (v) => setState(() => _esAdmin = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _cargando
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                    onPressed: _registrarUsuario,
                                    child: const Text('Registrar'),
                                  ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
