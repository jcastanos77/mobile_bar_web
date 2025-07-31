import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_bar_web/home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Iniciar sesión", style: TextStyle(fontSize: 24)),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Correo"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Contraseña"),
              ),
              if (error.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(error, style: TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text("Entrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registrar() async {
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Guarda usuario con rol en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': emailController.text.trim(),
        'admin': false,
      });

      setState(() {
        error = 'Usuario creado correctamente';
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> login() async {
    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));

    } on FirebaseAuthException catch (e) {
      print('Código de error: ${e.code}');
      print('Mensaje: ${e.message}');
      setState(() {
        error = e.toString();
      });
    }
  }

}