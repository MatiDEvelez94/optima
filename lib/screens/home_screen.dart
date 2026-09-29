import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/event_card.dart';
import '../widgets/gradient_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navyLight,
        foregroundColor: AppColors.cream,
        centerTitle: true,
        title: Text(
          'Inicio',
          style: AppText.title.copyWith(fontSize: 24, color: AppColors.cream),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.field,
              child: Text('V', style: AppText.title.copyWith(fontSize: 18)),
            ),
          ),
        ],
      ),
      // Menú lateral: se abre con el ícono de hamburguesa
      drawer: const Drawer(),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Eventos Activos',
                style: AppText.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Container(
                color: const Color(0xFFE6E3DC),
                height: 170,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: const [
                    EventCard(
                      image: 'assets/images/salon.jpg',
                      date: 'Sabado 12/9',
                      size: '250 personas',
                      schedule: '17:30hs - 5:30hs',
                      needs: [
                        'mozo (8)',
                        'bachero(3)',
                        'cocinero (2)',
                        'bachero (4)',
                        'limpieza (2)',
                        'animacion (1)',
                      ],
                    ),
                    SizedBox(width: 8),
                    EventCard(
                      image: 'assets/images/trabajo.jpg',
                      date: 'Domingo 13/9',
                      size: '120 personas',
                      schedule: '20:00hs - 2:00hs',
                      needs: ['mozo (4)', 'cocinero (1)'],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Historial de eventos',
                style: AppText.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ordenar por:', style: AppText.label),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    color: AppColors.field,
                    child: Text(
                      '(filtros)',
                      style: AppText.input.copyWith(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(
                'No has creado ningun\nevento aun',
                textAlign: TextAlign.center,
                style: AppText.subtitle.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}