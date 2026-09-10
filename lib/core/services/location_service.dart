import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String geoLocationString;
  final String? address;
  final bool isSuccess;
  final String? errorMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.geoLocationString,
    this.address,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory LocationResult.error(String message) {
    return LocationResult(
      latitude: 0.0,
      longitude: 0.0,
      geoLocationString: '0.0,0.0',
      address: null,
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        if (e is MissingPluginException || '$e'.contains('MissingPluginException')) {
          return LocationResult.error('Location service plugin not initialized.');
        }
        serviceEnabled = false;
      }

      if (!serviceEnabled) {
        return LocationResult.error(
            'Location services (GPS) are disabled. Please enable GPS on your device.');
      }

      LocationPermission permission = LocationPermission.whileInUse;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return LocationResult.error(
                'Location permission denied. GPS access is required to record attendance.');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          return LocationResult.error(
              'Location permissions are permanently denied. Please enable location permissions in app settings.');
        }
      } catch (e) {
        if (e is MissingPluginException || '$e'.contains('MissingPluginException')) {
          return LocationResult.error('Location permission plugin not initialized.');
        }
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      if (position == null) {
        return LocationResult.error(
            'Unable to acquire accurate GPS location. Please ensure you have a clear view of the sky and GPS is enabled.');
      }

      final lat = position.latitude;
      final long = position.longitude;

      final address = await reverseGeocode(lat, long);

      return LocationResult(
        latitude: lat,
        longitude: long,
        geoLocationString: '$lat,$long',
        address: address,
        isSuccess: true,
      );
    } catch (e) {
      return LocationResult.error('GPS location error: $e');
    }
  }

  static Future<String?> reverseGeocode(double lat, double long) async {
    // Force English locale for native geocoder if supported
    try {
      await geocoding.setLocaleIdentifier('en_US');
    } catch (_) {}

    // 1. Try native geocoding package in English
    try {
      final placemarks = await geocoding
          .placemarkFromCoordinates(lat, long)
          .timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];

        final mainName = p.name ?? p.thoroughfare ?? p.subThoroughfare;
        if (mainName != null &&
            mainName.trim().isNotEmpty &&
            !mainName.contains('+') &&
            mainName != p.locality &&
            mainName != p.country) {
          parts.add(mainName.trim());
        } else if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
          parts.add(p.subLocality!.trim());
        }

        if (p.locality != null &&
            p.locality!.trim().isNotEmpty &&
            !parts.contains(p.locality!.trim())) {
          parts.add(p.locality!.trim());
        }
        if (p.administrativeArea != null &&
            p.administrativeArea!.trim().isNotEmpty &&
            !parts.contains(p.administrativeArea!.trim()) &&
            parts.length < 2) {
          parts.add(p.administrativeArea!.trim());
        }
        if (p.country != null &&
            p.country!.trim().isNotEmpty &&
            !parts.contains(p.country!.trim())) {
          parts.add(p.country!.trim());
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    // 2. Fallback HTTP reverse geocode via Nominatim OpenStreetMap API (Forced English 'en')
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': long,
          'zoom': 18,
          'addressdetails': 1,
          'accept-language': 'en',
        },
        options: Options(
          headers: {
            'User-Agent': 'SharqiApp/1.0',
            'Accept-Language': 'en',
          },
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final addr = data['address'] as Map?;
        if (addr != null) {
          final parts = <String>[];

          final mainPlace = addr['hotel'] ??
              addr['building'] ??
              addr['amenity'] ??
              addr['office'] ??
              addr['road'] ??
              addr['suburb'] ??
              addr['neighbourhood'];
          if (mainPlace != null && mainPlace.toString().trim().isNotEmpty) {
            parts.add(mainPlace.toString().trim());
          }

          final city = addr['city'] ??
              addr['town'] ??
              addr['district'] ??
              addr['state'];
          if (city != null &&
              city.toString().trim().isNotEmpty &&
              !parts.contains(city.toString().trim())) {
            parts.add(city.toString().trim());
          }

          final country = addr['country'];
          if (country != null &&
              country.toString().trim().isNotEmpty &&
              !parts.contains(country.toString().trim())) {
            parts.add(country.toString().trim());
          }

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
        if (data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (_) {}

    return null;
  }
}
