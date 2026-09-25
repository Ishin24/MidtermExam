import 'package:flutter/material.dart';
import '../models/hero_model.dart';
import '../services/api_service.dart';

class HeroFormScreen extends StatefulWidget {
  final DotaHero? hero; // null => create mode, non-null => edit mode

  const HeroFormScreen({super.key, this.hero});

  @override
  State<HeroFormScreen> createState() => _HeroFormScreenState();
}

class _HeroFormScreenState extends State<HeroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  late TextEditingController _nameCtrl;
  late TextEditingController _localizedNameCtrl;
  late TextEditingController _rolesCtrl;
  late TextEditingController _imgUrlCtrl;
  late TextEditingController _loreCtrl;

  String _primaryAttr = 'Strength';
  String _attackType = 'Melee';
  bool _saving = false;

  bool get _isEditing => widget.hero != null;

  @override
  void initState() {
    super.initState();
    final h = widget.hero;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _localizedNameCtrl = TextEditingController(text: h?.localizedName ?? '');
    _rolesCtrl = TextEditingController(text: h?.roles ?? '');
    _imgUrlCtrl = TextEditingController(text: h?.imgUrl ?? '');
    _loreCtrl = TextEditingController(text: h?.lore ?? '');
    if (h != null) {
      _primaryAttr = h.primaryAttr.isNotEmpty ? h.primaryAttr : 'Strength';
      _attackType = h.attackType.isNotEmpty ? h.attackType : 'Melee';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _localizedNameCtrl.dispose();
    _rolesCtrl.dispose();
    _imgUrlCtrl.dispose();
    _loreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final hero = DotaHero(
      id: widget.hero?.id,
      name: _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      localizedName: _localizedNameCtrl.text.trim(),
      primaryAttr: _primaryAttr,
      attackType: _attackType,
      roles: _rolesCtrl.text.trim(),
      imgUrl: _imgUrlCtrl.text.trim(),
      lore: _loreCtrl.text.trim(),
    );

    try {
      if (_isEditing) {
        await _api.updateHero(hero);
      } else {
        await _api.createHero(hero);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Hero" : "Add Hero")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _localizedNameCtrl,
              decoration: const InputDecoration(labelText: "Hero Name *", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Hero name is required" : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _primaryAttr,
              decoration: const InputDecoration(labelText: "Primary Attribute *", border: OutlineInputBorder()),
              items: const ['Strength', 'Agility', 'Intelligence', 'Universal']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _primaryAttr = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _attackType,
              decoration: const InputDecoration(labelText: "Attack Type *", border: OutlineInputBorder()),
              items: const ['Melee', 'Ranged']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _attackType = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _rolesCtrl,
              decoration: const InputDecoration(
                labelText: "Roles (comma-separated)",
                hintText: "Carry, Support, Nuker",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imgUrlCtrl,
              decoration: const InputDecoration(labelText: "Image URL", border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final ok = Uri.tryParse(v)?.isAbsolute ?? false;
                return ok ? null : "Enter a valid URL";
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loreCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Lore / Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? "Save Changes" : "Create Hero"),
            ),
          ],
        ),
      ),
    );
  }
}
