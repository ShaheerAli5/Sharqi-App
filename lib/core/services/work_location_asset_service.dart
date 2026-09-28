import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/work_location_item.dart';

class WorkLocationAssetService {
  static const String assetPath = 'assets/data/work_locations.json';
  static const double fallbackRadiusMeters = 100;

  final AssetBundle _bundle;
  List<WorkLocationItem>? _cachedLocations;

  WorkLocationAssetService({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  Future<List<WorkLocationItem>> loadLocations() async {
    final cached = _cachedLocations;
    if (cached != null) return cached;

    final rawJson = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException('Invalid work-location asset format.');
    }

    final locations = decoded
        .whereType<Map>()
        .map((item) => WorkLocationItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) =>
            item.id > 0 &&
            item.name.trim().isNotEmpty &&
            item.latitude != null &&
            item.longitude != null)
        .toList(growable: false);
    _cachedLocations = locations;
    return locations;
  }

  Future<WorkLocationItem?> findLocation({
    int? locationId,
    String locationName = '',
  }) async {
    final locations = await loadLocations();
    if (locationId != null) {
      for (final location in locations) {
        if (location.id == locationId) return location;
      }
    }

    final requestedName = _normalizeName(locationName);
    if (requestedName.isEmpty) return null;
    for (final location in locations) {
      if (_normalizeName(location.name) == requestedName) return location;
    }
    return null;
  }

  static String _normalizeName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
