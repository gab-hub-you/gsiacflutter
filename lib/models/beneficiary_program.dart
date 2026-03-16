enum BenefitType { financial, food, medical, scholarship, discount }

class BeneficiaryProgram {
  final String id;
  final String name;
  final String description;
  final List<String> requirements;
  final BenefitType type;
  final String paymentSchedule;
  final double? amount;

  BeneficiaryProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.requirements,
    required this.type,
    required this.paymentSchedule,
    this.amount,
  });

  factory BeneficiaryProgram.fromJson(Map<String, dynamic> json) {
    return BeneficiaryProgram(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      requirements: List<String>.from(json['requirements'] ?? []),
      type: BenefitType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BenefitType.financial,
      ),
      paymentSchedule: json['payment_schedule'] ?? 'Monthly',
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requirements': requirements,
      'type': type.name,
      'payment_schedule': paymentSchedule,
      'amount': amount,
    };
  }
}
