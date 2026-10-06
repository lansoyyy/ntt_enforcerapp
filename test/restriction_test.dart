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
  TimeOfDay? start = const TimeOfDay(hour: 8, minute: 0),
  TimeOfDay? end = const TimeOfDay(hour: 17, minute: 0),
  double latitude = 17.6132,
  double longitude = 121.7270,
  double radius = 1500,
}) {
  return EnforcerRestriction(
    startTime: start,
    endTime: end,
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

    test('allows any time when there is no schedule', () {
      final restriction = _restriction(start: null, end: null);

      expect(restriction.hasTimeRestriction, isFalse);
      expect(restriction.isWithinTime(DateTime(2026, 10, 4, 3, 0)), isTrue);
    });

    test('supports overnight windows', () {
      final restriction = _restriction(
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 6, minute: 0),
      );

      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 23, 0)), isTrue);
      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 5, 30)), isTrue);
      expect(restriction.isWithinTime(DateTime(2026, 9, 28, 12, 0)), isFalse);
    });
  });

  group('EnforcerRestriction.parseTime', () {
    test('parses API time strings', () {
      final time = EnforcerRestriction.parseTime('08:22');

      expect(time, const TimeOfDay(hour: 8, minute: 22));
    });

    test('returns null for invalid values', () {
      expect(EnforcerRestriction.parseTime(null), isNull);
      expect(EnforcerRestriction.parseTime(''), isNull);
      expect(EnforcerRestriction.parseTime('8am'), isNull);
      expect(EnforcerRestriction.parseTime('25:00'), isNull);
      expect(EnforcerRestriction.parseTime('10:75'), isNull);
    });
  });

  group('EnforcerLocation.fromJson', () {
    test('parses string coordinates returned by the API', () {
      final location = EnforcerLocation.fromJson({
        'id': 1,
        'name': 'QA Test Spot',
        'latitude': '17.6056826',
        'longitude': '121.7123044',
      });

      expect(location.id, 1);
      expect(location.name, 'QA Test Spot');
      expect(location.latitude, closeTo(17.6056826, 0.0000001));
      expect(location.longitude, closeTo(121.7123044, 0.0000001));
      expect(location.radiusMeters, isNull);
    });

    test('converts the radius from kilometers to meters', () {
      final location = EnforcerLocation.fromJson({
        'id': 1,
        'name': 'Test',
        'latitude': '13.0216848',
        'longitude': '121.1044917',
        'radius': '2',
      });

      expect(location.radiusMeters, 2000);
    });

    test('round trips through toJson', () {
      const location = EnforcerLocation(
        id: 2,
        name: 'Robinsons Rontonda',
        latitude: 17.6267935,
        longitude: 121.7324638,
      );

      final parsed = EnforcerLocation.fromJson(location.toJson());

      expect(parsed.id, 2);
      expect(parsed.name, 'Robinsons Rontonda');
      expect(parsed.latitude, 17.6267935);
      expect(parsed.longitude, 121.7324638);
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

  group('RestrictionService.resolveRestriction', () {
    test('uses the provided restriction without hitting the API', () async {
      final restriction = _restriction();
      final service = RestrictionService(restriction: restriction);

      expect(await service.resolveRestriction(), same(restriction));
    });
  });

  group('RestrictionService.check', () {
    test('rejects outside schedule without resolving location', () async {
      var resolverCalled = false;
      final service = RestrictionService(
        restriction: _restriction(),
        clock: () => DateTime(2026, 9, 28, 6, 0), // Before the 8:00 AM start.
        locationResolver: ({required bool requestPermission}) async {
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
        locationResolver: ({required bool requestPermission}) async =>
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
        locationResolver: ({required bool requestPermission}) async =>
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
        locationResolver: ({required bool requestPermission}) async =>
            const LocationResolution.failure(
          RestrictionStatus.locationServiceDisabled,
        ),
      );

      final result = await service.check();

      expect(result.status, RestrictionStatus.locationServiceDisabled);
    });

    test('passes requestPermission through to the resolver', () async {
      bool? receivedRequestPermission;

      final service = RestrictionService(
        restriction: _restriction(),
        requestPermission: false,
        clock: () => DateTime(2026, 9, 28, 10, 0),
        locationResolver: ({required bool requestPermission}) async {
          receivedRequestPermission = requestPermission;
          return LocationResolution.success(_position(17.6132, 121.7270));
        },
      );

      await service.check();

      expect(receivedRequestPermission, isFalse);
    });
  });
}
