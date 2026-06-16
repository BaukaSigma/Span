import 'package:flutter/material.dart';

import 'constants.dart';

/// Ensures every date picker uses the same white background and Russian text.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  SelectableDayPredicate? selectableDayPredicate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    initialEntryMode: initialEntryMode,
    initialDatePickerMode: initialDatePickerMode,
    selectableDayPredicate: selectableDayPredicate,
    helpText: helpText ?? 'Выберите дату',
    cancelText: cancelText ?? 'Отмена',
    confirmText: confirmText ?? 'Готово',
    locale: const Locale('ru', 'RU'),
    builder: (context, child) {
      final baseTheme = Theme.of(context);
      return Theme(
        data: baseTheme.copyWith(
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.white),
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: AppColors.primary,
            onSurface: AppColors.black,
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: AppColors.white,
            headerBackgroundColor: AppColors.white,
            surfaceTintColor: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );
}
