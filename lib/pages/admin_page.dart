import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _valorPagadoController = TextEditingController();

  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;
  String? _sexo;
  String? _tipoPlan;
  String _edadCalculada = '';

  final CollectionReference usuarios = FirebaseFirestore.instance.collection(
    'Usuario',
  );

  int calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  void actualizarEdad() {
    if (_fechaNacimiento != null) {
      final edad = calcularEdad(_fechaNacimiento!);
      setState(() {
        _edadCalculada = edad.toString();
      });
    }
  }

  Future<void> registrarUsuario() async {
    if (_fechaNacimiento == null ||
        _fechaIngreso == null ||
        _sexo == null ||
        _tipoPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final int edad = calcularEdad(_fechaNacimiento!);

    await usuarios.add({
      'cedula': _cedulaController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'fechaNacimiento': _fechaNacimiento!.toIso8601String(),
      'fecha': _fechaIngreso!.toIso8601String(),
      'edad': edad.toString(),
      'sexo': _sexo!,
      'tipoPlan': _tipoPlan!,
      'valor_pagado': _valorPagadoController.text.trim(),
      'rol': 'usuario',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario registrado correctamente')),
    );

    _cedulaController.clear();
    _nombreController.clear();
    _telefonoController.clear();
    _valorPagadoController.clear();

    setState(() {
      _fechaNacimiento = null;
      _fechaIngreso = null;
      _sexo = null;
      _tipoPlan = null;
      _edadCalculada = '';
    });
  }

  Future<void> buscarUsuario() async {
    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty) return;

    final query = await usuarios.where('cedula', isEqualTo: cedula).get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data() as Map<String, dynamic>;

      setState(() {
        _nombreController.text = data['nombre'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _valorPagadoController.text = data['valor_pagado'] ?? '';
        _tipoPlan = data['tipoPlan'] ?? '';
        _sexo = data['sexo'] ?? '';
        _fechaNacimiento =
            data['fechaNacimiento'] != null
                ? DateTime.tryParse(data['fechaNacimiento'])
                : null;
        _fechaIngreso =
            data['fecha'] != null ? DateTime.tryParse(data['fecha']) : null;
        _edadCalculada = data['edad'] ?? '';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario encontrado')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
    }
  }

  Future<void> _seleccionarFecha(Function(DateTime) onFechaSeleccionada) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (fecha != null) onFechaSeleccionada(fecha);
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const InicioPage()),
                    (route) => false,
                  );
                },
                child: const Text('Sí'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Usuario')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: _confirmarCerrarSesion,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cedulaController,
              decoration: const InputDecoration(labelText: 'Cédula'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            DropdownButton<String>(
              value: _tipoPlan,
              hint: const Text('Selecciona el tipo de plan'),
              isExpanded: true,
              items:
                  ['Mensual', 'Bimestre', 'Trimestre']
                      .map(
                        (plan) =>
                            DropdownMenuItem(value: plan, child: Text(plan)),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() {
                  _tipoPlan = val;
                });
              },
            ),
            TextField(
              controller: _valorPagadoController,
              decoration: const InputDecoration(labelText: 'Valor pagado'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _fechaNacimiento == null
                      ? 'Nacimiento: No seleccionada'
                      : 'Nacimiento: ${_fechaNacimiento!.toLocal().toString().split(' ')[0]}',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      () => _seleccionarFecha((f) {
                        setState(() {
                          _fechaNacimiento = f;
                          actualizarEdad();
                        });
                      }),
                  child: const Text('Seleccionar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Edad: $_edadCalculada años'),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _fechaIngreso == null
                      ? 'Ingreso: No seleccionada'
                      : 'Ingreso: ${_fechaIngreso!.toLocal().toString().split(' ')[0]}',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      () => _seleccionarFecha(
                        (f) => setState(() => _fechaIngreso = f),
                      ),
                  child: const Text('Seleccionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _sexo,
              hint: const Text('Selecciona el sexo'),
              isExpanded: true,
              items:
                  ['Masculino', 'Femenino', 'Otro']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (val) => setState(() => _sexo = val),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: registrarUsuario,
                    child: const Text('Registrar Usuario'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: buscarUsuario,
                    child: const Text('Buscar Usuario'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
