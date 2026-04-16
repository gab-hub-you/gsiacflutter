enum VerificationStatus { unverified, pending, verified, rejected }
enum UserRole { citizen, barangayStaff, municipalStaff }

class Citizen {
  final String id;
  final String username;
  final String? profilePictureUrl;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? suffix;
  final String? sex;
  final String? status; // Civil Status (Single, Married, etc.)
  final String address;
  final DateTime birthdate;
  final String email;
  final String? phoneNumber;
  final String? town;
  final String? barangay;
  final String? govIdUrl;
  final String? selfieUrl;
  final VerificationStatus verificationStatus;
  final String lifeStatus; // Active/Deceased
  final UserRole role;

  Citizen({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
    this.sex,
    this.status,
    required this.address,
    required this.birthdate,
    required this.email,
    this.phoneNumber,
    this.town,
    this.barangay,
    this.govIdUrl,
    this.selfieUrl,
    this.verificationStatus = VerificationStatus.unverified,
    this.lifeStatus = 'Active',
    this.role = UserRole.citizen,
  });

  String get fullName => '$firstName ${middleName != null && middleName!.isNotEmpty ? "$middleName " : ""}$lastName${suffix != null && suffix!.isNotEmpty ? " $suffix" : ""}';

  String get displayName => verificationStatus == VerificationStatus.verified ? fullName : username;

  factory Citizen.fromJson(Map<String, dynamic> json) {
    // Helper to handle both camelCase and snake_case from different sources (Auth vs DB)
    T? getValue<T>(String camel, String snake) => (json[camel] ?? json[snake]) as T?;

    return Citizen(
      id: json['id'],
      username: json['username'] ?? '',
      profilePictureUrl: getValue('profilePictureUrl', 'profile_picture_url'),
      firstName: getValue('firstName', 'first_name') ?? '',
      lastName: getValue('lastName', 'last_name') ?? '',
      middleName: getValue('middleName', 'middle_name'),
      suffix: json['suffix'],
      sex: json['sex'],
      status: json['status'],
      address: json['address'] ?? '',
      birthdate: DateTime.tryParse(json['birthdate'] ?? '') ?? DateTime.now(),
      email: json['email'] ?? '',
      phoneNumber: getValue('phoneNumber', 'phone_number'),
      town: json['town'],
      barangay: json['barangay'],
      govIdUrl: getValue('govIdUrl', 'gov_id_url'),
      selfieUrl: getValue('selfieUrl', 'selfie_url'),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == getValue<String>('verificationStatus', 'verification_status'),
        orElse: () => VerificationStatus.unverified,
      ),
      lifeStatus: getValue('lifeStatus', 'life_status') ?? 'Active',
      role: UserRole.values.firstWhere(
        (e) => e.name == getValue<String>('role', 'role'),
        orElse: () => UserRole.citizen,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'suffix': suffix,
      'sex': sex,
      'status': status,
      'address': address,
      'birthdate': birthdate.toIso8601String(),
      'email': email,
      'phone_number': phoneNumber,
      'town': town,
      'barangay': barangay,
      'gov_id_url': govIdUrl,
      'selfie_url': selfieUrl,
      'verification_status': verificationStatus.name,
      'life_status': lifeStatus,
      'role': role.name,
    };
  }
}
