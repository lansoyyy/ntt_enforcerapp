import 'package:enforcer_app/utlis/colors.dart';
import 'package:flutter/material.dart';

Future<DateTime?> datePickerWidget(
    BuildContext context, DateTime selectedDate) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: primary, // Header background color

          colorScheme: ColorScheme.light(primary: primary), // Selection color
          buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary, // Text color
          ),
        ),
        child: child!,
      );
    },
  );

  return picked;
}
