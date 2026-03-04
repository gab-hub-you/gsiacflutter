class Citizen {
  final String id;
  final String fullName;
  final String address;
  final DateTime birthdate;
  final String email;
  final String status; // Active/Deceased

  Citizen({
    required this.id,
    required this.fullName,
    required this.address,
    required this.birthdate,
    required this.email,
    this.status = 'Active',
  });

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      id: json['id'],
      fullName: json['fullName'],
      address: json['address'],
      birthdate: DateTime.parse(json['birthdate']),
      email: json['email'],
      status: json['status'] ?? 'Active',
    );
  }
}
