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

class EnforcerRestriction {
  const EnforcerRestriction({
    required this.startTime,
    required this.endTime,
    required this.allowedWeekdays,
    required this.area,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Days the enforcer may issue tickets, using [DateTime] weekday constants
  /// (1 = Monday ... 7 = Sunday).
  final Set<int> allowedWeekdays;

  final EnforcementArea area;

  bool isWithinTime(DateTime now) {
    if (!allowedWeekdays.contains(now.weekday)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

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

  String get scheduleLabel => '${formatTimeOfDay(startTime)} - '
      '${formatTimeOfDay(endTime)}';

  String get weekdayLabel {
    if (allowedWeekdays.length >= 7) return 'Daily';

    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    if (allowedWeekdays.length == 6 &&
        !allowedWeekdays.contains(DateTime.sunday)) {
      return 'Monday to Saturday';
    }

    final sorted = allowedWeekdays.toList()..sort();
    return sorted.map((day) => names[day]).join(', ');
  }

  String get radiusLabel {
    final radius = area.radiusMeters;
    if (radius < 1000) return '${radius.round()} m';
    return '${(radius / 1000).toStringAsFixed(1)} km';
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
