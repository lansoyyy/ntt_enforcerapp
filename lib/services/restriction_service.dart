import 'dart:async';

import 'package:enforcer_app/models/enforcer_restriction.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Hardcoded sample used until the backend API exposes the real per-enforcer
/// restrictions.
///
/// TODO(api): replace [sampleRestriction] with data returned by the API. The
/// expected shape (subject to backend confirmation) is something like:
/// {
///   "schedule": {
///     "start": "08:00",
///     "end": "17:00",
///     "days": [1, 2, 3, 4, 5, 6]
///   },
///   "area": {
///     "name": "Tuguegarao City",
///     "latitude": 17.6132,
///     "longitude": 121.7270,
///     "radius_meters": 1500
///   }
/// }
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
    radiusMeters: 1500,
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

typedef LocationResolver = Future<LocationResolution> Function();

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
  })  : restriction = restriction ?? sampleRestriction,
        _locationResolver = locationResolver ?? _resolveLocationFromDevice,
        _clock = clock ?? DateTime.now;

  final EnforcerRestriction restriction;
  final LocationResolver _locationResolver;
  final DateTime Function() _clock;

  Future<RestrictionCheckResult> check() async {
    if (!restriction.isWithinTime(_clock())) {
      return RestrictionCheckResult(
        status: RestrictionStatus.outsideSchedule,
        restriction: restriction,
      );
    }

    final resolution = await _locationResolver();
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

  static Future<LocationResolution> _resolveLocationFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResolution.failure(
          RestrictionStatus.locationServiceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
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
