class Place {
  final String name;
  final String category; // 'cafe' o 'study_room'
  final String? address;
  final double lat;
  final double lon;
  final double? distanceM;

  const Place({
    required this.name,
    required this.category,
    this.address,
    required this.lat,
    required this.lon,
    this.distanceM,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        name: json['name'] as String? ?? 'Posto sconosciuto',
        category: json['category'] as String? ?? 'cafe',
        address: json['address'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        distanceM: json['distance_m'] != null
            ? (json['distance_m'] as num).toDouble()
            : null,
      );
}
