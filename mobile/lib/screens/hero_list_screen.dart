import 'package:flutter/material.dart';
import '../models/hero_model.dart';
import '../services/api_service.dart';
import '../widgets/hero_card.dart';
import 'hero_detail_screen.dart';
import 'hero_form_screen.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
  final ApiService _api = ApiService();
  late Future<List<DotaHero>> _futureHeroes;

  @override
  void initState() {
    super.initState();
    // Assign directly: calling _refresh() here would setState() during build.
    _futureHeroes = _api.getHeroes();
  }

  void _refresh() {
    setState(() {
      _futureHeroes = _api.getHeroes();
    });
  }

  Future<void> _goToForm({DotaHero? hero}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HeroFormScreen(hero: hero)),
    );
    if (result == true) _refresh();
  }

  Future<void> _goToDetail(DotaHero hero) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HeroDetailScreen(heroId: hero.id!)),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<DotaHero>>(
          future: _futureHeroes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Could not reach the API.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            final heroes = snapshot.data ?? [];
            if (heroes.isEmpty) {
              return const Center(child: Text("No heroes yet. Tap + to add one."));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: heroes.length,
              itemBuilder: (context, index) {
                final hero = heroes[index];
                return HeroCard(hero: hero, onTap: () => _goToDetail(hero));
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(),
        tooltip: 'Add Hero',
        child: const Icon(Icons.add),
      ),
    );
  }
}
