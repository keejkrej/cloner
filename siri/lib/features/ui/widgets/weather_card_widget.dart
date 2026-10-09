import 'package:flutter/material.dart';

class WeatherCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final city = data['city']?.toString() ?? 'Berlin';
    final temp = (data['temperature'] as num?)?.round() ?? 16;
    final condition = data['condition']?.toString() ?? 'Clear';
    final wind = (data['wind'] as num?)?.round() ?? 10;
    final humidity = (data['humidity'] as num?)?.round() ?? 50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3C72).withValues(alpha: 0.8),
            const Color(0xFF2A5298).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                city,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 28),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            condition,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$temp°',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: Colors.white),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Wind: $wind km/h',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  Text(
                    'Humidity: $humidity%',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
