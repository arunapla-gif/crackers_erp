const List<String> indianStatesAndUts = [
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

String normalizeIndianState(String? raw, {String fallback = 'Tamil Nadu'}) {
  final clean = (raw ?? '').trim();
  if (clean.isEmpty) return fallback;
  final lower = clean.toLowerCase();
  for (final state in indianStatesAndUts) {
    if (state.toLowerCase() == lower) {
      return state;
    }
  }
  if (lower == 'tn') return 'Tamil Nadu';
  if (lower == 'ka') return 'Karnataka';
  if (lower == 'kl') return 'Kerala';
  if (lower == 'mh') return 'Maharashtra';
  if (lower == 'ap') return 'Andhra Pradesh';
  if (lower == 'ts' || lower == 'tg') return 'Telangana';
  return clean;
}

