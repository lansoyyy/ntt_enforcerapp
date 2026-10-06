import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnforcementArea {
  const EnforcementArea({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

class EnforcerLocation {
  const EnforcerLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters,
  });

  /// Parses the `location` object embedded in the user data.
  ///
  /// The API sends `radius` in kilometers (e.g. `"2"`), so it is converted to
  /// meters here.
  factory EnforcerLocation.fromJson(Map<String, dynamic> json) {
    final radiusKm = double.tryParse('${json['radius']}');

    return EnforcerLocation(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: double.tryParse('${json['latitude']}') ?? 0,
      longitude: double.tryParse('${json['longitude']}') ?? 0,
      radiusMeters: radiusKm == null ? null : radiusKm * 1000,
    );
  }

  final int id;
  final String name;
  final double latitude;
  final double longitude;

  /// Radius in meters, or `null` when the API did not provide one.
  final double? radiusMeters;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (radiusMeters != null) 'radius': radiusMeters! / 1000,
    };
  }
}

class EnforcerRestriction {
  const EnforcerRestriction({
    required this.area,
    this.startTime,
    this.endTime,
  });

  final EnforcementArea area;

  /// Allowed time window from the enforcer's schedule. When either value is
  /// `null` there is no app-side time restriction (the backend still
  /// validates).
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  bool get hasTimeRestriction => startTime != null && endTime != null;

  bool isWithinTime(DateTime now) {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return true;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }

    // Overnight window, e.g. 10:00 PM - 6:00 AM.
    return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
  }

  bool isWithinArea(double latitude, double longitude) {
    return distanceInMeters(latitude, longitude) <= area.radiusMeters;
  }

  double distanceInMeters(double latitude, double longitude) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(latitude - area.latitude);
    final dLng = _toRadians(longitude - area.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(area.latitude)) *
            math.cos(_toRadians(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  String get scheduleLabel {
    if (!hasTimeRestriction) return 'No time restriction';
    return '${formatTimeOfDay(startTime!)} - ${formatTimeOfDay(endTime!)}';
  }

  String get radiusLabel {
    final radius = area.radiusMeters;
    if (radius < 1000) return '${radius.round()} m';
    return '${(radius / 1000).toStringAsFixed(1)} km';
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null) return null;

    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
