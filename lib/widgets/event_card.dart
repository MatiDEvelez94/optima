import 'package:flutter/material.dart';
import '../screens/event_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.image,
    required this.date,
    required this.size,
    required this.schedule,
    required this.needs,
  });

  final String image;
  final String date;
  final String size;
  final String schedule;
  final List<String> needs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              image: image,
              date: date,
              size: size,
              schedule: schedule,
              needs: needs,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 320,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: double.infinity,
              child: Image.asset(image, fit: BoxFit.cover),
            ),
            Expanded(
              child: Container(
                color: AppColors.navy,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: AppText.eventText),
                    Text('Dimension: $size', style: AppText.eventText),
                    const SizedBox(height: 6),
                    Text('Horario: $schedule', style: AppText.eventText),
                    const SizedBox(height: 6),
                    Text('Busca:', style: AppText.eventText),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: needs
                          .map(
                            (n) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.field,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                n,
                                style: AppText.eventText.copyWith(
                                  color: AppColors.navy,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Mas información',
                        style: AppText.eventText.copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}