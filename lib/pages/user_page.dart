import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPage extends StatefulWidget {
  final String id;

  const UserPage({Key? key, required this.id}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String? fechaVencimiento;
  String? nombreUsuario;
  bool buscando = false;

  @override
  void initState() {
    super.initState();
    buscarUsuario(); // 🔍 Buscar automáticamente al iniciar
  }

  Future<void> buscarUsuario() async {
    setState(() {
      buscando = true;
      fechaVencimiento = null;
      nombreUsuario = null;
    });

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('Usuario')
              .where(
                'cedula',
                isEqualTo: widget.id.trim(),
              ) // <--- Usar widget.id
              .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          nombreUsuario = data['nombre'];

          var fecha = data['fecha'];
          if (fecha is Timestamp) {
            fechaVencimiento =
                fecha.toDate().toLocal().toString().split(' ')[0];
          } else if (fecha is String) {
            fechaVencimiento = fecha.split('T')[0]; // elimina la hora
          } else {
            fechaVencimiento = 'Formato de fecha no válido';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró un usuario con ese ID')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al buscar: $e')));
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
        child:
            buscando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (nombreUsuario != null && fechaVencimiento != null)
                      Column(
                        children: [
                          Text(
                            'Hola, $nombreUsuario',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tu fecha de vencimiento es:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fechaVencimiento!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('No se encontraron datos del usuario.'),
                  ],
                ),
      ),
    );
  }
}
