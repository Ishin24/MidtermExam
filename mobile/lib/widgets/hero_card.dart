import 'package:flutter/material.dart';
import '../models/hero_model.dart';

Color attrColor(String attr) {
  switch (attr) {
    case 'Strength':
      return const Color(0xFFB33A3A);
    case 'Agility':
      return const Color(0xFF2E8B57);
    case 'Intelligence':
      return const Color(0xFF3A6EA5);
    default:
      return const Color(0xFF8A6D3B);
  }
}

class HeroCard extends StatelessWidget {
  final DotaHero hero;
  final VoidCallback onTap;

  const HeroCard({super.key, required this.hero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = attrColor(hero.primaryAttr);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: hero.imgUrl.isNotEmpty
                  ? Image.network(
                      hero.imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: color.withOpacity(0.15),
                        child: const Icon(Icons.shield, size: 40),
                      ),
                    )
                  : Container(
                      color: color.withOpacity(0.15),
                      child: const Icon(Icons.shield, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero.localizedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hero.primaryAttr,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
