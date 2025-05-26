import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio_page.dart'; // Asegúrate de que esta ruta sea correcta

// Importar para Normalización de String
import 'package:diacritic/diacritic.dart';

class AdminPage extends StatefulWidget {
  final String cedulaAdmin;

  const AdminPage({Key? key, required this.cedulaAdmin}) : super(key: key);

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
  String edadCalculada = '';

  String? nombreAdmin;

  final CollectionReference usuarios = FirebaseFirestore.instance.collection(
    'Usuario',
  );

  // Para guardar el ID del documento del usuario actualmente cargado/seleccionado
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    obtenerNombreAdmin();
  }

  // Función de normalización: convierte a minúsculas y remueve tildes
  String _normalizeString(String text) {
    String normalized = text.toLowerCase();
    normalized = removeDiacritics(normalized);
    return normalized;
  }

  Future<void> obtenerNombreAdmin() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Admin')
              .where('cedula', isEqualTo: widget.cedulaAdmin.trim())
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          nombreAdmin = data['nombre'] ?? 'Administrador';
        });
      } else {
        setState(() {
          nombreAdmin = 'Administrador';
        });
      }
    } catch (e) {
      setState(() {
        nombreAdmin = 'Administrador';
      });
      // Opcional: Log the error
      // print("Error al obtener nombre del admin: $e");
    }
  }

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
        edadCalculada = edad.toString();
      });
    }
  }

  // --- Función para cargar los datos de un usuario en los campos ---
  void _cargarDatosUsuarioEnFormulario(
    Map<String, dynamic> userData,
    String documentId,
  ) {
    setState(() {
      _currentUserId = documentId; // Guarda el ID del documento
      _cedulaController.text = userData['cedula'] ?? '';
      _nombreController.text = userData['nombre'] ?? '';
      _telefonoController.text = userData['telefono'] ?? '';
      _valorPagadoController.text = (userData['valor_pagado'] ?? '').toString();
      _tipoPlan = userData['tipoPlan'] ?? '';
      _sexo = userData['sexo'] ?? '';
      _fechaNacimiento =
          userData['fechaNacimiento'] != null
              ? DateTime.tryParse(userData['fechaNacimiento'])
              : null;
      _fechaIngreso =
          userData['fecha'] != null
              ? DateTime.tryParse(userData['fecha'])
              : null;
      edadCalculada = (userData['edad'] ?? '').toString();
    });
    // Actualizar edad si se cargó una fecha de nacimiento
    if (_fechaNacimiento != null) {
      actualizarEdad();
    }
  }

  Future<void> registrarOActualizarUsuario() async {
    if (_fechaNacimiento == null ||
        _fechaIngreso == null ||
        _sexo == null ||
        _tipoPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos obligatorios (Fecha Nacimiento, Fecha Ingreso, Sexo, Tipo Plan)',
          ),
        ),
      );
      return;
    }

    final cedula = _cedulaController.text.trim();
    final nombre = _nombreController.text.trim();

    if (cedula.isEmpty || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cédula y el nombre no pueden estar vacíos.'),
        ),
      );
      return;
    }

    final int edad = calcularEdad(_fechaNacimiento!);
    final usuarioData = {
      'cedula': cedula,
      'nombre': nombre,
      'nombre_normalized': _normalizeString(
        nombre,
      ), // <<-- Nuevo campo normalizado
      'telefono': _telefonoController.text.trim(),
      'fechaNacimiento': _fechaNacimiento!.toIso8601String(),
      'fecha': _fechaIngreso!.toIso8601String(), // Esto es fecha de ingreso
      'edad': edad.toString(),
      'sexo': _sexo!,
      'tipoPlan': _tipoPlan!,
      'valor_pagado':
          _valorPagadoController.text
              .trim(), // Considera que esto es el último pago
      'rol': 'usuario',
    };

    try {
      if (_currentUserId != null) {
        // Si hay un ID de usuario actual, actualizamos ese documento
        await usuarios.doc(_currentUserId).update(usuarioData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado correctamente')),
        );
      } else {
        // Si no hay un ID de usuario actual, buscamos por cédula para ver si existe
        final query = await usuarios.where('cedula', isEqualTo: cedula).get();
        if (query.docs.isNotEmpty) {
          // Si existe, lo actualizamos
          await usuarios.doc(query.docs.first.id).update(usuarioData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado (por cédula) correctamente'),
            ),
          );
        } else {
          // Si no existe, lo registramos como nuevo
          await usuarios.add(usuarioData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado correctamente')),
          );
        }
      }
      limpiarCampos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar/actualizar usuario: $e')),
      );
    }
  }

  void limpiarCampos() {
    _cedulaController.clear();
    _nombreController.clear();
    _telefonoController.clear();
    _valorPagadoController.clear();

    setState(() {
      _currentUserId = null; // Limpiar el ID del documento al limpiar campos
      _fechaNacimiento = null;
      _fechaIngreso = null;
      _sexo = null;
      _tipoPlan = null;
      edadCalculada = '';
    });
  }

  // --- Función principal para buscar usuario (modificada para nombre y cédula) ---
  Future<void> buscarUsuario({bool byCedula = true}) async {
    List<DocumentSnapshot> results = [];
    String searchTerm = '';

    if (byCedula) {
      searchTerm = _cedulaController.text.trim();
    } else {
      searchTerm = _nombreController.text.trim();
      // Normalizar el término de búsqueda para nombres
      searchTerm = _normalizeString(searchTerm);
    }

    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cédula o un nombre para buscar.'),
        ),
      );
      return;
    }

    try {
      if (byCedula) {
        // Búsqueda por cédula (exacta)
        final query =
            await usuarios.where('cedula', isEqualTo: searchTerm).get();
        results = query.docs;
      } else {
        // Búsqueda por nombre (similar, case-insensitive, sin tildes)
        // Usamos el campo normalizado 'nombre_normalized'
        final query =
            await usuarios
                .where('nombre_normalized', isGreaterThanOrEqualTo: searchTerm)
                .where(
                  'nombre_normalized',
                  isLessThanOrEqualTo: '$searchTerm\uf8ff',
                )
                .get();
        results = query.docs;
      }

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
        limpiarCampos(); // Limpia los campos si no se encuentra nada
      } else if (results.length == 1) {
        // Si solo hay un resultado, lo cargamos directamente
        final data = results.first.data() as Map<String, dynamic>;
        _cargarDatosUsuarioEnFormulario(data, results.first.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario encontrado')));
      } else {
        // Si hay múltiples resultados, mostramos el diálogo
        await _mostrarResultadosBusqueda(results);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al buscar usuario: $e')));
    }
  }

  // --- Función para mostrar el diálogo de resultados de búsqueda ---
  Future<void> _mostrarResultadosBusqueda(List<DocumentSnapshot> users) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un usuario'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final userId = users[index].id;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(userData['nombre'] ?? 'Nombre desconocido'),
                    subtitle: Text(userData['cedula'] ?? 'Cédula desconocida'),
                    onTap: () {
                      _cargarDatosUsuarioEnFormulario(userData, userId);
                      Navigator.of(context).pop(); // Cerrar el diálogo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Usuario ${userData['nombre']} seleccionado',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar sin seleccionar
                limpiarCampos(); // Opcional: limpiar campos si se cancela
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // --- Función temporal para añadir 'nombre_normalized' a usuarios existentes ---
  // Ejecuta esto UNA SOLA VEZ para actualizar tu base de datos.
  // Luego, puedes eliminar esta función y el botón que la llama.
  Future<void> _addNormalizedNameToExistingUsers() async {
    // Cierra el Drawer antes de mostrar el SnackBar
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando sincronización de nombres...')),
    );
    try {
      final querySnapshot =
          await usuarios
              .get(); // Obtiene todos los documentos de la colección 'Usuario'

      for (var doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final String currentName = userData['nombre'] ?? '';

        // Solo actualiza si el campo no existe o si el valor normalizado es diferente
        if (!userData.containsKey('nombre_normalized') ||
            _normalizeString(currentName) != userData['nombre_normalized']) {
          final String normalizedName = _normalizeString(currentName);
          await doc.reference.update({'nombre_normalized': normalizedName});
          print(
            'Usuario ${userData['nombre']} (${doc.id}) actualizado con nombre_normalized: $normalizedName',
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronización de nombres completada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar nombres: $e')),
      );
    }
  }

  Future<void> _seleccionarFecha(Function(DateTime) onFechaSeleccionada) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'), // Para español
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
                  Navigator.of(context).pop();
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
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        // El icono del menú del Drawer se genera automáticamente si hay un Drawer
        // y no se especifica un leading widget.
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  nombreAdmin ?? 'Cargando...',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sync), // Ícono para la sincronización
              title: const Text('Sincronizar Nombres Existentes'),
              onTap: _addNormalizedNameToExistingUsers, // Llamada a la función
            ),
            ListTile(
              leading: const Icon(Icons.logout), // Icono de cerrar sesión
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
              keyboardType: TextInputType.number, // Asegurar teclado numérico
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
            Text('Edad: $edadCalculada años'),
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
                    onPressed: registrarOActualizarUsuario,
                    child: const Text('Registrar / Actualizar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () =>
                            buscarUsuario(byCedula: true), // Buscar por Cédula
                    child: const Text('Buscar Cédula'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Espacio entre los botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () =>
                            buscarUsuario(byCedula: false), // Buscar por Nombre
                    child: const Text('Buscar Nombre'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: limpiarCampos, // Botón para limpiar campos
                    child: const Text('Limpiar Campos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // La sección de "Usuarios por vencer" se mantiene igual
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('Usuario').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No hay usuarios registrados.');
                }

                final hoy = DateTime.now();
                // Calcula la fecha de mañana para comparar correctamente
                final manana = DateTime(hoy.year, hoy.month, hoy.day + 1);

                final usuarios = snapshot.data!.docs;

                final usuariosPorVencer =
                    usuarios.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final tipoPlan = data['tipoPlan'];
                      final fechaIngresoStr = data['fecha'];

                      if (tipoPlan == null || fechaIngresoStr == null)
                        return false;

                      final diasPlan =
                          {
                            'Mensual': 30,
                            'Bimestre': 60,
                            'Trimestre': 90,
                          }[tipoPlan];

                      if (diasPlan == null) return false;

                      final fechaIngreso = DateTime.tryParse(fechaIngresoStr);
                      if (fechaIngreso == null) return false;

                      final fechaVencimiento = fechaIngreso.add(
                        Duration(days: diasPlan),
                      );
                      // Compara solo año, mes y día para la fecha de vencimiento
                      return fechaVencimiento.year == manana.year &&
                          fechaVencimiento.month == manana.month &&
                          fechaVencimiento.day == manana.day;
                    }).toList();

                if (usuariosPorVencer.isEmpty) {
                  return const Text('No hay usuarios por vencer mañana.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuarios por vencer mañana:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...usuariosPorVencer.map((usuario) {
                      final data = usuario.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '- ${data['nombre'] ?? 'Sin nombre'} (Cédula: ${data['cedula'] ?? 'N/A'})',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
