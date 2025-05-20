import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_page.dart';
import 'user_page.dart';

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
      final snapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('id', isEqualTo: idIngresado)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final bool esAdmin = data['rol'] == 'admin';

        if (esAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserPage()),
          );
        }
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo_gimnasio.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tu ID',
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
                                  'Log in',
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
