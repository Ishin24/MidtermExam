import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dota_heroes_app/main.dart';
import 'package:dota_heroes_app/services/api_service.dart';

void main() {
  test('app entrypoint builds a widget', () {
    expect(const DotaHeroesApp(), isA<Widget>());
  });

  test('api base url targets the local backend', () {
    expect(ApiService.baseUrl, contains('/dota-heroes-app/backend/heroes'));
  });
}
