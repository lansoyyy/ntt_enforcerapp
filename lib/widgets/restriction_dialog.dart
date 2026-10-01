import 'package:enforcer_app/services/restriction_service.dart';
import 'package:flutter/material.dart';

/// Checks the enforcer's time and area restrictions while showing a progress
/// dialog, then a message dialog when the check fails.
///
/// Returns the [RestrictionCheckResult] (which includes the position captured
/// during the check) or `null` when the result could not be determined.
Future<RestrictionCheckResult?> runEnforcementRestrictionCheck(
  BuildContext context,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Text(
              'Checking your enforcement schedule and area...',
              style: TextStyle(fontFamily: 'QRegular'),
            ),
          ),
        ],
      ),
    ),
  );

  RestrictionCheckResult? result;
  try {
    result = await RestrictionService().check();
  } catch (_) {
    result = null;
  } finally {
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
  }

  if (result == null || !context.mounted) return result;

  final checkResult = result;

  if (!checkResult.isAllowed) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          checkResult.title,
          style: const TextStyle(
            fontFamily: 'QBold',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          checkResult.message,
          style: const TextStyle(fontFamily: 'QRegular'),
        ),
        actions: <Widget>[
          MaterialButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'QRegular',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  return result;
}

/// Convenience wrapper for callers that only need to know if the enforcer may
/// continue.
Future<bool> ensureWithinEnforcementRestriction(BuildContext context) async {
  final result = await runEnforcementRestrictionCheck(context);
  return result?.isAllowed ?? false;
}
