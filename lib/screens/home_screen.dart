import 'package:flutter/material.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import '../repositories/cuenta_repository.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import 'admin_salones_tab.dart';
import 'admin_solicitudes_tab.dart';
import 'explorar_tab.dart';
import 'home_tab.dart';
import 'historial_trabajos_screen.dart';
import 'home_tab_salon.dart';
import 'profile_screen.dart';
import 'salon_en_revision_tab.dart';

// Marco de la app con la barra de navegación de abajo.
// Administrador: casita = Solicitudes, lupa = Salones activos, rayitas = Perfil
// Dueño de salon: casita = Inicio, lupa = Explorar, tres rayitas = Perfil
// Mozo: casita = Inicio, lupa = Historial, tres rayitas = Perfil
// Invitado: casita = Inicio, tres rayitas = Perfil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _actualizar();
  }

  // Trae de la base de datos lo que pudo haber cambiado (salon aprobado,
  // eventos nuevos, postulaciones, avisos...) y vuelve a dibujar las pestañas
  Future<void> _actualizar() async {
    await CuentaRepository.refrescar();
    if (mounted) setState(() {});
    await EventoRepository.refrescar();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = UserSession.logueado && UserSession.rol == 'admin';
    final esSalon = UserSession.logueado && UserSession.rol == 'salon';
    final esMozo = UserSession.logueado && UserSession.rol == 'mozo';
    final tresTabs = esAdmin || esSalon || esMozo;
    final double iconSize = tresTabs ? 26 : 30;

    // El dueño solo puede crear eventos cuando el admin aprobo su salon
    final estadoSalon = UserSession.solicitudSalon?.estado;
    final salonAprobado =
        estadoSalon == null || estadoSalon == EstadoSalon.aprobada;

    // Sin const a proposito: asi cada pestaña se vuelve a dibujar al tocarla
    // y muestra los datos mas nuevos (por ejemplo despues de editar el salon)
    final List<Widget> pages;
    if (esAdmin) {
      pages = [AdminSolicitudesTab(), AdminSalonesTab(), ProfileScreen()];
    } else if (esSalon) {
      pages = [
        salonAprobado ? HomeTabSalon() : SalonEnRevisionTab(),
        ExplorarTab(),
        ProfileScreen(),
      ];
    } else if (esMozo) {
      pages = [
        HomeTab(),
        HistorialTrabajosScreen(esPestana: true),
        ProfileScreen(),
      ];
    } else {
      pages = [HomeTab(), ProfileScreen()];
    }

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined, size: iconSize),
        activeIcon: Icon(Icons.home, size: iconSize),
        label: esAdmin ? 'Solicitudes' : 'Inicio',
      ),
      if (tresTabs)
        BottomNavigationBarItem(
          icon: Icon(Icons.search, size: iconSize),
          label: esAdmin ? 'Salones' : (esMozo ? 'Historial' : 'Explorar'),
        ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu, size: iconSize),
        label: 'Perfil',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          _actualizar();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navyLight,
        selectedItemColor: AppColors.cream,
        unselectedItemColor: AppColors.cream.withValues(alpha: 0.55),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showSelectedLabels: tresTabs,
        showUnselectedLabels: tresTabs,
        items: items,
      ),
    );
  }
}