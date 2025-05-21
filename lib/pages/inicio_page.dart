import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_page.dart';
import 'user_page.dart';
// import 'package:delta_mobile/main.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({Key? key}) : super(key: key);

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final TextEditingController _idController = TextEditingController();
  bool cargando = false;

  Future<void> verificarID() async {
    String idIngresado = _idController.text.trim();

    if (idIngresado.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Por favor ingresa un ID')));
      return;
    }

    setState(() => cargando = true);

    try {
      // Buscar primero en Admin
      final adminSnapshot =
          await FirebaseFirestore.instance
              .collection('Admin')
              .where('cedula', isEqualTo: idIngresado)
              .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData = adminSnapshot.docs.first.data();
        final rol = adminData['rol'] ?? '';

        if (rol == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdminPage(
                    cedulaAdmin: idIngresado,
                  ), // <-- PASAR LA CÉDULA AQUÍ
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserPage(id: idIngresado),
            ), // ✅ Pasar el ID
          );
        }
        return;
      }

      // Si no está en Admin, buscar en Usuario
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('Usuario')
              .where('cedula', isEqualTo: idIngresado)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserPage(id: idIngresado),
          ), // ✅ Pasar el ID
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ID no encontrado')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
          // Container(
          //   decoration: const BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('assets/fondo_gimnasio.jpg'),
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
          // Capa oscura con desenfoque (Glassmorphism)
          Container(color: Colors.black.withOpacity(0.6)),
          // Contenido de login
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bienvenido a Fuerza Delta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tu cédula',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ID',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cargando ? null : verificarID,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            cargando
                                ? const CircularProgressIndicator()
                                : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
