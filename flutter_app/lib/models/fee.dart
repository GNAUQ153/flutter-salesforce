class Fee {
  final String id;
  final String sfId; // Salesforce Id
  final String courseName;
  final String dueDate;
  final int amount;
  String status;

  Fee({
    required this.id,
    required this.sfId,
    required this.courseName,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'],
      sfId: json['sfId'],
      courseName: json['courseName'],
      dueDate: json['dueDate'],
      amount: json['amount'],
      status: json['status'],
    );
  }
}
