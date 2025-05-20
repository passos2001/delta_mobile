import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final TextEditingController _idController = TextEditingController();
  String? fechaVencimiento;
  String? nombreUsuario;
  bool buscando = false;

  Future<void> buscarUsuario() async {
    setState(() {
      buscando = true;
      fechaVencimiento = null;
      nombreUsuario = null;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('id', isEqualTo: _idController.text.trim())
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          nombreUsuario = data['nombre'];
          fechaVencimiento = (data['fechaVencimiento'] as Timestamp)
              .toDate()
              .toLocal()
              .toString()
              .split(' ')[0];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró un usuario con ese ID')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar: $e')),
      );
    } finally {
      setState(() {
        buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultar Vencimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu ID',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: buscarUsuario,
              child: buscando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Buscar'),
            ),
            const SizedBox(height: 32),
            if (nombreUsuario != null && fechaVencimiento != null)
              Column(
                children: [
                  Text(
                    'Hola, $nombreUsuario',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu fecha de vencimiento es:',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fechaVencimiento!,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
