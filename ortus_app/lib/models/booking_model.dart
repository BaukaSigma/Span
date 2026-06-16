class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String trainerId;
  final String trainerName;
  final String trainerPhone;
  final DateTime trainingDate;
  final String slot;
  final String status;
  final String comment;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.trainerId,
    required this.trainerName,
    required this.trainerPhone,
    required this.trainingDate,
    required this.slot,
    required this.status,
    required this.comment,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final client = json['clientId'];
    final trainer = json['trainerId'];

    return BookingModel(
      id: json['_id']?.toString() ?? '',
      clientId: client is Map ? client['_id']?.toString() ?? '' : (client?.toString() ?? ''),
      clientName: client is Map ? client['fullName']?.toString() ?? '' : '',
      clientPhone: client is Map ? client['phoneNumber']?.toString() ?? '' : '',
      trainerId: trainer is Map ? trainer['_id']?.toString() ?? '' : (trainer?.toString() ?? ''),
      trainerName: trainer is Map ? trainer['fullName']?.toString() ?? '' : '',
      trainerPhone: trainer is Map ? trainer['phoneNumber']?.toString() ?? '' : '',
      trainingDate: DateTime.tryParse(json['trainingDate']?.toString() ?? '') ?? DateTime.now(),
      slot: json['slot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      comment: json['comment']?.toString() ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}
