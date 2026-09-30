import 'package:enforcer_app/models/enforcer_restriction.dart';
import 'package:enforcer_app/services/restriction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Position _position(double latitude, double longitude) => Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

EnforcerRestriction _restriction({
  TimeOfDay start = const TimeOfDay(hour: 8, minute: 0),
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0),
  Set<int> days = const {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  },
  double latitude = 17.6132,
  double longitude = 121.7270,
  double radius = 1500,
}) {
  return EnforcerRestriction(
    startTime: start,
    endTime: end,
    allowedWeekdays: days,
    area: EnforcementArea(
      name: 'Test Area',
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radius,
    ),
  );
}

void main() {
  group('EnforcerRestriction.isWithinTime', () {
    test('allows a weekday inside the window', () {
      final restriction = _restriction();

      // Monday, Sept 28 2026, 10:00 AM.
      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 10, 0)), isTrue);
    });

    test('rejects times before the start', () {
      final restriction = _restriction();

      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 7, 59)), isFalse);
    });

    test('includes the end time', () {
      final restriction = _restriction();

      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 17, 0)), isTrue);
    });

    test('rejects disallowed weekdays', () {
      final restriction = _restriction();

      // Sunday, Oct 4 2026.
      expect(restriction.isWithinTime(DateTime(2026, 10, 4, 10, 0)), isFalse);
    });

    test('supports overnight windows', () {
      final restriction = _restriction(
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 6, minute: 0),
        days: const {1, 2, 3, 4, 5, 6, 7},
      );

      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 23, 0)), isTrue);
      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 5, 30)), isTrue);
      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 12, 0)), isFalse);
    });
  });

  group('EnforcerRestriction distance', () {
    test('is zero at the area center', () {
      final restriction = _restriction();

      expect(restriction.distanceInMeters(17.6132, 121.7270), closeTo(0, 0.01));
    });

    test('matches a known distance within tolerance', () {
      final restriction = _restriction();

      // 0.01 degrees of longitude at ~17.61 latitude is roughly 1060 m.
      expect(
        restriction.distanceInMeters(17.6132, 121.7370),
        closeTo(1060, 30),
      );
    });

    test('isWithinArea respects the radius', () {
      final restriction = _restriction(radius: 500);

      expect(restriction.isWithinArea(17.6132, 121.7270), isTrue);
      expect(restriction.isWithinArea(17.6132, 121.7370), isFalse);
    });
  });

  group('RestrictionService.check', () {
    test('rejects outside schedule without resolving location', () async {
      var resolverCalled = false;
      final service = RestrictionService(
        restriction: _restriction(),
        clock: () => DateTime(2026, 10, 4, 10, 0), // Sunday.
        locationResolver: () async {
          resolverCalled = true;
          return const LocationResolution.failure(
            RestrictionStatus.locationUnavailable,
          );
        },
      );

      final result = await service.check();

      expect(result.status, RestrictionStatus.outsideSchedule);
      expect(resolverCalled, isFalse);
    });

    test('allows when inside schedule and area', () async {
      final service = RestrictionService(
        restriction: _restriction(),
        clock: () => DateTime(2026, 9, 28, 10, 0),
        locationResolver: () async =>
            LocationResolution.success(_position(17.6132, 121.7270)),
      );

      final result = await service.check();

      expect(result.status, RestrictionStatus.allowed);
      expect(result.isAllowed, isTrue);
    });

    test('rejects with distance when outside the area', () async {
      final service = RestrictionService(
        restriction: _restriction(radius: 500),
        clock: () => DateTime(2026, 9, 28, 10, 0),
        locationResolver: () async =>
            LocationResolution.success(_position(17.6132, 121.7370)),
      );

      final result = await service.check();

      expect(result.status, RestrictionStatus.outsideArea);
      expect(result.distanceMeters, greaterThan(500));
      expect(result.message, contains('Test Area'));
    });

    test('propagates location failures', () async {
      final service = RestrictionService(
        restriction: _restriction(),
        clock: () => DateTime(2026, 9, 28, 10, 0),
        locationResolver: () async => const LocationResolution.failure(
          RestrictionStatus.locationServiceDisabled,
        ),
      );

      final result = await service.check();

      expect(result.status, RestrictionStatus.locationServiceDisabled);
    });
  });
}
