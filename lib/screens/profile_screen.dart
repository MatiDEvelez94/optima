import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evento.dart';
import '../models/evento_aceptado.dart';
import '../models/postulacion.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cuenta_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import 'change_password_screen.dart';
import 'editar_perfil_screen.dart';
import 'editar_salon_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'recorte_foto_screen.dart';
import 'role_screen.dart';

// Cierra la sesion (tambien en el servidor) y vuelve a la app como invitado.
// Los eventos y postulaciones que todavia viven en memoria se borran.
void _cerrarSesion(BuildContext context) async {
  await AuthRepository.cerrarSesion(); // cierra la sesión en el servidor
  UserSession.cuentaActual?.guardarSesion();
  UserSession.cerrarSesion();
  Evento.eliminarActivo();
  Postulacion.enviadas.clear();
  EventoAceptado.aceptados.clear();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  // Elegir o cambiar la foto de perfil (se guarda en la base de datos)
  Future<void> _cambiarFoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final original = await picked.readAsBytes();
    if (!mounted) return;
    // Pantalla para encuadrar la foto a gusto (circulo guia)
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => RecorteFotoScreen(bytes: original, circular: true),
      ),
    );
    if (bytes == null || !mounted) return;
    try {
      await CuentaRepository.guardarFoto(bytes);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      UserSession.foto = bytes;
      UserSession.cuentaActual?.foto = bytes;
    });
  }

  // 4,5 (3 calificaciones) / Sin calificaciones
  String _textoCalificacion() {
    final cuenta = UserSession.cuentaActual;
    final promedio = cuenta?.promedio;
    if (cuenta == null || promedio == null) return 'Sin calificaciones';
    final n = cuenta.calificaciones.length;
    return '${Evento.formatoEstrellas(promedio)} de 5 '
        '($n ${n == 1 ? 'calificacion' : 'calificaciones'})';
  }

  @override
  Widget build(BuildContext context) {
    if (!UserSession.logueado) return const _GuestProfile();
    if (UserSession.rol == 'admin') return const _AdminProfile();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.navyLight,
        foregroundColor: AppColors.cream,
        centerTitle: true,
        title: Text(
          'Perfil',
          style: AppText.title.copyWith(fontSize: 24, color: AppColors.cream),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil: se toca para elegir o cambiar
              Center(
                child: GestureDetector(
                  onTap: _cambiarFoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 57,
                        backgroundColor: AppColors.navy,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.field,
                          backgroundImage: UserSession.foto != null
                              ? MemoryImage(UserSession.foto!)
                              : null,
                          child: UserSession.foto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.hint,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cream,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _InfoField(label: 'Nombre', value: UserSession.nombre),
              _InfoField(label: 'Apellido', value: UserSession.apellido),
              _InfoField(
                label: 'Correo electrónico',
                value: UserSession.correo,
              ),
              _InfoField(label: 'Teléfono', value: UserSession.telefono),
              _InfoField(label: 'DNI', value: UserSession.dni),
              if (UserSession.rol == 'mozo')
                _InfoField(label: 'Calificación', value: _textoCalificacion()),
              const SizedBox(height: 16),
              Center(
                child: OptimaButton(
                  text: 'Editar datos',
                  filled: false,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditarPerfilScreen(),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              if (UserSession.rol == 'salon') ...[
                const SizedBox(height: 12),
                Center(
                  child: OptimaButton(
                    text: 'Editar salón',
                    filled: false,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditarSalonScreen(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: OptimaButton(
                  text: 'Cambiar contraseña',
                  filled: false,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OptimaButton(
                  text: 'Cerrar sesión',
                  filled: false,
                  onPressed: () => _cerrarSesion(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navy),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppText.input.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// Perfil del administrador: su cuenta y un resumen
class _AdminProfile extends StatelessWidget {
  const _AdminProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.navyLight,
        foregroundColor: AppColors.cream,
        centerTitle: true,
        title: Text(
          'Perfil',
          style: AppText.title.copyWith(fontSize: 24, color: AppColors.cream),
        ),
      ),
      body: GradientBackground(
        child: ValueListenableBuilder<int>(
          valueListenable: SolicitudSalon.cambios,
          builder: (context, _, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 57,
                      backgroundColor: AppColors.navy,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.field,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _InfoField(label: 'Rol', value: 'Administrador'),
                  _InfoField(
                    label: 'Correo electrónico',
                    value: UserSession.correo,
                  ),
                  _InfoField(
                    label: 'Solicitudes pendientes',
                    value: '${SolicitudSalon.pendientes.length}',
                  ),
                  _InfoField(
                    label: 'Salones activos',
                    value: '${SolicitudSalon.activos.length}',
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OptimaButton(
                      text: 'Cerrar sesión',
                      filled: false,
                      onPressed: () => _cerrarSesion(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Lo que ve alguien que todavia no tiene cuenta (pestaña de las 3 rayitas)
class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.navyLight,
        foregroundColor: AppColors.cream,
        centerTitle: true,
        title: Text(
          'Perfil',
          style: AppText.title.copyWith(fontSize: 24, color: AppColors.cream),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            children: [
              const Icon(Icons.person_outline, size: 72, color: AppColors.navy),
              const SizedBox(height: 16),
              Text(
                'Aún no tienes cuenta',
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea tu cuenta para inscribir tu salón o buscar trabajo',
                textAlign: TextAlign.center,
                style: AppText.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
              ),
              const SizedBox(height: 32),
              OptimaButton(
                text: 'Crea una cuenta',
                width: double.infinity,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              OptimaLink(
                text: 'Ya tengo cuenta',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}