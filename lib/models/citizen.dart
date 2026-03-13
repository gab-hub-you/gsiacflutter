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
    return Citizen(
      id: json['id'],
      username: json['username'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? json['profile_picture_url'],
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      middleName: json['middleName'] ?? json['middle_name'],
      suffix: json['suffix'],
      sex: json['sex'],
      status: json['status'],
      address: json['address'] ?? '',
      birthdate: DateTime.tryParse(json['birthdate'] ?? '') ?? DateTime.now(),
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      town: json['town'],
      barangay: json['barangay'],
      govIdUrl: json['govIdUrl'] ?? json['gov_id_url'],
      selfieUrl: json['selfieUrl'] ?? json['selfie_url'],
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == (json['verificationStatus'] ?? json['verification_status']),
        orElse: () => VerificationStatus.unverified,
      ),
      lifeStatus: json['lifeStatus'] ?? json['life_status'] ?? 'Active',
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'citizen'),
        orElse: () => UserRole.citizen,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'suffix': suffix,
      'sex': sex,
      'status': status,
      'address': address,
      'birthdate': birthdate.toIso8601String(),
      'email': email,
      'phoneNumber': phoneNumber,
      'town': town,
      'barangay': barangay,
      'govIdUrl': govIdUrl,
      'selfieUrl': selfieUrl,
      'verificationStatus': verificationStatus.name,
      'lifeStatus': lifeStatus,
      'role': role.name,
    };
  }
}
