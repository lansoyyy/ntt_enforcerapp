import 'dart:async';
import 'dart:convert';

import 'package:enforcer_app/models/enforcer_restriction.dart';
import 'package:enforcer_app/network/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// Radius used for the assigned area check until the backend exposes it.
const double defaultRadiusMeters = 2000;

/// Fallback schedule/area used when the API has no restriction data yet.
///
/// The schedule is hardcoded for now; the area center is replaced by the
/// enforcer's assigned location from `GET /lgus/{lguId}/locations` whenever
/// it is available.
const EnforcerRestriction sampleRestriction = EnforcerRestriction(
  startTime: TimeOfDay(hour: 8, minute: 0),
  endTime: TimeOfDay(hour: 17, minute: 0),
  allowedWeekdays: {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  },
  area: EnforcementArea(
    name: 'Tuguegarao City',
    latitude: 17.6132,
    longitude: 121.7270,
    radiusMeters: defaultRadiusMeters,
  ),
);

enum RestrictionStatus {
  allowed,
  outsideSchedule,
  outsideArea,
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationUnavailable,
}

class LocationResolution {
  const LocationResolution.success(this.position) : status = null;
  const LocationResolution.failure(this.status) : position = null;

  final Position? position;
  final RestrictionStatus? status;
}

typedef LocationResolver = Future<LocationResolution> Function({
  required bool requestPermission,
});

class RestrictionCheckResult {
  const RestrictionCheckResult({
    required this.status,
    required this.restriction,
    this.position,
    this.distanceMeters,
  });

  final RestrictionStatus status;
  final EnforcerRestriction restriction;
  final Position? position;
  final double? distanceMeters;

  bool get isAllowed => status == RestrictionStatus.allowed;

  String get title {
    switch (status) {
      case RestrictionStatus.allowed:
        return 'Restriction Check Passed';
      case RestrictionStatus.outsideSchedule:
        return 'Outside Enforcement Hours';
      case RestrictionStatus.outsideArea:
        return 'Outside Assigned Area';
      case RestrictionStatus.locationServiceDisabled:
        return 'Location Services Disabled';
      case RestrictionStatus.locationPermissionDenied:
        return 'Location Permission Required';
      case RestrictionStatus.locationPermissionDeniedForever:
        return 'Location Permission Blocked';
      case RestrictionStatus.locationUnavailable:
        return 'Location Unavailable';
    }
  }

  String get message {
    switch (status) {
      case RestrictionStatus.allowed:
        return 'You are within your enforcement schedule and assigned area.';
      case RestrictionStatus.outsideSchedule:
        return 'Tickets can only be issued on ${restriction.weekdayLabel} '
            'between ${restriction.scheduleLabel}.';
      case RestrictionStatus.outsideArea:
        return 'You are currently $distanceLabel away from '
            '${restriction.area.name}. You must be within '
            '${restriction.radiusLabel} of the assigned area to issue a '
            'ticket.';
      case RestrictionStatus.locationServiceDisabled:
        return 'Please turn on your device location (GPS) to verify that you '
            'are within your assigned area.';
      case RestrictionStatus.locationPermissionDenied:
        return 'Allow location access so the app can verify that you are '
            'within your assigned area.';
      case RestrictionStatus.locationPermissionDeniedForever:
        return 'Location access is permanently denied. Enable it in the '
            'device settings to issue tickets.';
      case RestrictionStatus.locationUnavailable:
        return 'We could not determine your current location. Move to an open '
            'area and try again.';
    }
  }

  String get distanceLabel {
    final distance = distanceMeters;
    if (distance == null) return 'an unknown distance';

    if (distance < 1000) return '${distance.round()} m';
    return '${(distance / 1000).toStringAsFixed(2)} km';
  }
}

class RestrictionService {
  RestrictionService({
    EnforcerRestriction? restriction,
    LocationResolver? locationResolver,
    DateTime Function()? clock,
    bool requestPermission = true,
  })  : _providedRestriction = restriction,
        _locationResolver = locationResolver ?? _resolveLocationFromDevice,
        _clock = clock ?? DateTime.now,
        _requestPermission = requestPermission;

  static const String _assignedAreaKey = 'assigned_area';
  static const Duration _memoryCacheTtl = Duration(minutes: 5);

  static EnforcerRestriction? _memoryCache;
  static String? _memoryCacheKey;
  static DateTime? _memoryCacheAt;

  final EnforcerRestriction? _providedRestriction;
  final LocationResolver _locationResolver;
  final DateTime Function() _clock;
  final bool _requestPermission;

  /// Clears the in-memory restriction cache (e.g. on logout).
  static void clearCache() {
    _memoryCache = null;
    _memoryCacheKey = null;
    _memoryCacheAt = null;
  }

  /// Resolves the enforcer's restriction.
  ///
  /// When a restriction was explicitly provided (e.g. in tests) it is used
  /// as-is. Otherwise the assigned location is loaded from the API
  /// (`GET /lgus/{lguId}/locations` matched by `location_id` from `/me`),
  /// falling back to the last cached area and finally to [sampleRestriction].
  Future<EnforcerRestriction> resolveRestriction() async {
    final provided = _providedRestriction;
    if (provided != null) return provided;

    final box = GetStorage();
    final cacheKey = '${box.read('lgu_id')}-${box.read('location_id')}';

    if (_memoryCache != null &&
        _memoryCacheKey == cacheKey &&
        _memoryCacheAt != null &&
        DateTime.now().difference(_memoryCacheAt!) < _memoryCacheTtl) {
      return _memoryCache!;
    }

    try {
      final lguId = box.read('lgu_id');
      final locationId = box.read('location_id');

      if (lguId != null) {
        final locations = await _fetchLocations('$lguId');
        final location = _matchLocation(locations, locationId);

        if (location != null) {
          box.write(_assignedAreaKey, jsonEncode(location.toJson()));
          return _cache(_restrictionWithArea(location), cacheKey);
        }
      }
    } catch (_) {
      // Fall through to the cached/sample restriction below.
    }

    final cached = _readCachedArea();
    if (cached != null) return _cache(_restrictionWithArea(cached), cacheKey);

    return sampleRestriction;
  }

  EnforcerRestriction _cache(EnforcerRestriction restriction, String key) {
    _memoryCache = restriction;
    _memoryCacheKey = key;
    _memoryCacheAt = DateTime.now();
    return restriction;
  }

  Future<RestrictionCheckResult> check() async {
    final restriction = await resolveRestriction();

    if (!restriction.isWithinTime(_clock())) {
      return RestrictionCheckResult(
        status: RestrictionStatus.outsideSchedule,
        restriction: restriction,
      );
    }

    final resolution = await _locationResolver(
      requestPermission: _requestPermission,
    );
    final position = resolution.position;

    if (position == null) {
      return RestrictionCheckResult(
        status: resolution.status ?? RestrictionStatus.locationUnavailable,
        restriction: restriction,
      );
    }

    final distance = restriction.distanceInMeters(
      position.latitude,
      position.longitude,
    );

    if (distance > restriction.area.radiusMeters) {
      return RestrictionCheckResult(
        status: RestrictionStatus.outsideArea,
        restriction: restriction,
        position: position,
        distanceMeters: distance,
      );
    }

    return RestrictionCheckResult(
      status: RestrictionStatus.allowed,
      restriction: restriction,
      position: position,
      distanceMeters: distance,
    );
  }

  EnforcerLocation? _matchLocation(
    List<EnforcerLocation> locations,
    Object? locationId,
  ) {
    if (locations.isEmpty) return null;

    if (locationId == null) {
      return locations.length == 1 ? locations.first : null;
    }

    for (final location in locations) {
      if (location.id.toString() == locationId.toString()) return location;
    }

    return null;
  }

  EnforcerRestriction _restrictionWithArea(EnforcerLocation location) {
    return EnforcerRestriction(
      startTime: sampleRestriction.startTime,
      endTime: sampleRestriction.endTime,
      allowedWeekdays: sampleRestriction.allowedWeekdays,
      area: EnforcementArea(
        name: location.name,
        latitude: location.latitude,
        longitude: location.longitude,
        radiusMeters: defaultRadiusMeters,
      ),
    );
  }

  EnforcerLocation? _readCachedArea() {
    try {
      final raw = GetStorage().read(_assignedAreaKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return EnforcerLocation.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<EnforcerLocation>> _fetchLocations(String lguId) async {
    final token = GetStorage().read('token');
    final url = Uri.parse('${ApiEndpoints.baseUrl}lgus/$lguId/locations');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);
    final list = decoded is Map ? decoded['data'] : decoded;
    if (list is! List) return [];

    return list
        .whereType<Map>()
        .map((item) => EnforcerLocation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<LocationResolution> _resolveLocationFromDevice({
    required bool requestPermission,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResolution.failure(
          RestrictionStatus.locationServiceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!requestPermission) {
          return const LocationResolution.failure(
            RestrictionStatus.locationPermissionDenied,
          );
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResolution.failure(
          RestrictionStatus.locationPermissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResolution.failure(
          RestrictionStatus.locationPermissionDeniedForever,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return LocationResolution.success(position);
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp) <
              const Duration(minutes: 2)) {
        return LocationResolution.success(lastKnown);
      }
      return const LocationResolution.failure(
        RestrictionStatus.locationUnavailable,
      );
    } catch (_) {
      return const LocationResolution.failure(
        RestrictionStatus.locationUnavailable,
      );
    }
  }
}
