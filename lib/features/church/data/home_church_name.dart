const kFamilyHouseHomeChurchPrefix = 'Family House Home Church';

String composeHomeChurchName(String familyName) {
  final family = familyName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (family.isEmpty) return kFamilyHouseHomeChurchPrefix;
  return '$kFamilyHouseHomeChurchPrefix @ $family Residence';
}
