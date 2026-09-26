import 'package:flutter/material.dart';
import '../models/hero_model.dart';
import '../services/api_service.dart';
import '../widgets/hero_card.dart';
import 'hero_form_screen.dart';

class HeroDetailScreen extends StatefulWidget {
  final int heroId;
  const HeroDetailScreen({super.key, required this.heroId});

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  final ApiService _api = ApiService();
  late Future<DotaHero> _futureHero;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    // Assign directly: calling _load() here would setState() during build.
    _futureHero = _api.getHero(widget.heroId);
  }

  void _load() {
    setState(() {
      _futureHero = _api.getHero(widget.heroId);
    });
  }

  Future<void> _confirmDelete(DotaHero hero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete hero?"),
        content: Text("This will permanently remove ${hero.localizedName} from the database."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteHero(hero.id!);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Hero Details")),
        body: FutureBuilder<DotaHero>(
          future: _futureHero,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("${snapshot.error}"));
            }
            final hero = snapshot.data!;
            final color = attrColor(hero.primaryAttr);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hero.imageUrl.isNotEmpty)
                    Image.network(
                      hero.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 220,
                        color: color.withOpacity(0.15),
                        child: const Icon(Icons.shield, size: 60),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hero.localizedName,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(hero.primaryAttr, style: const TextStyle(color: Colors.white)),
                              backgroundColor: color,
                            ),
                            Chip(label: Text(hero.attackType)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text("Roles", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: hero.roleList.map((r) => Chip(label: Text(r))).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text("Lore", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(hero.lore.isNotEmpty ? hero.lore : "No lore provided."),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text("Edit"),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => HeroFormScreen(hero: hero)),
                                  );
                                  if (result == true) {
                                    _changed = true;
                                    _load();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                icon: const Icon(Icons.delete),
                                label: const Text("Delete"),
                                onPressed: () => _confirmDelete(hero),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
