import 'package:flutter/material.dart';

import '../../../core/design_system/fhc_tokens.dart';

enum KcaAssignmentKind { standard, written, practical, soulWinning }

KcaAssignmentKind parseKcaAssignmentKind(Object? raw) {
  switch ('$raw'.trim().toLowerCase().replaceAll('-', '_')) {
    case 'soul_winning':
    case 'soulwinning':
      return KcaAssignmentKind.soulWinning;
    case 'practical':
      return KcaAssignmentKind.practical;
    case 'written':
      return KcaAssignmentKind.written;
    default:
      return KcaAssignmentKind.standard;
  }
}

bool kcaAssignmentRequiresMedia(KcaAssignmentKind kind) {
  return kind == KcaAssignmentKind.practical ||
      kind == KcaAssignmentKind.written ||
      kind == KcaAssignmentKind.soulWinning;
}

String kcaAssignmentKindLabel(KcaAssignmentKind kind) {
  return switch (kind) {
    KcaAssignmentKind.soulWinning => 'Soul winning',
    KcaAssignmentKind.practical => 'Practical',
    KcaAssignmentKind.written => 'Written',
    KcaAssignmentKind.standard => 'Standard',
  };
}

IconData kcaAssignmentKindIcon(KcaAssignmentKind kind) {
  return switch (kind) {
    KcaAssignmentKind.soulWinning => Icons.favorite_outline,
    KcaAssignmentKind.practical => Icons.camera_alt_outlined,
    KcaAssignmentKind.written => Icons.menu_book_outlined,
    KcaAssignmentKind.standard => Icons.assignment_outlined,
  };
}

Color kcaAssignmentKindColor(KcaAssignmentKind kind) {
  return switch (kind) {
    KcaAssignmentKind.soulWinning => FhcColors.gold,
    KcaAssignmentKind.practical => FhcColors.greenDark,
    KcaAssignmentKind.written => FhcColors.green,
    KcaAssignmentKind.standard => FhcColors.greenDark,
  };
}

List<Map<String, Object?>> flattenKcaSoulTree(Object? tree) {
  if (tree is! List) return const [];
  final out = <Map<String, Object?>>[];
  for (final node in tree) {
    if (node is! Map) continue;
    final map = <String, Object?>{
      for (final entry in node.entries) '${entry.key}': entry.value,
    };
    out.add(map);
    out.addAll(flattenKcaSoulTree(map['children']));
  }
  return out;
}
