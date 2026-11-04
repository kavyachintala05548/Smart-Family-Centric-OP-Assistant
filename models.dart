class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phone_number'],
        role: json['role'] ?? 'patient',
      );
}

class FamilyMemberModel {
  final int id;
  final String name;
  final int? age;
  final String? gender;
  final String? relationship;
  final String? medicalNotes;

  FamilyMemberModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.relationship,
    this.medicalNotes,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(
        id: json['id'],
        name: json['name'] ?? '',
        age: json['age'],
        gender: json['gender'],
        relationship: json['relationship'],
        medicalNotes: json['medical_notes'],
      );
}

class DoctorModel {
  final int id;
  final String fullName;
  final String specialty;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? city;
  final double consultationFee;
  final double averageRating;
  final int? totalReviews;
  final int? waitingTime;
  final String? profileDescription;

  DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialty,
    this.hospitalName,
    this.hospitalAddress,
    this.city,
    required this.consultationFee,
    required this.averageRating,
    this.totalReviews,
    this.waitingTime,
    this.profileDescription,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        id: json['id'],
        fullName: json['full_name'] ?? '',
        specialty: json['specialty'] ?? '',
        hospitalName: json['hospital_name'],
        hospitalAddress: json['hospital_address'],
        city: json['city'],
        consultationFee: double.tryParse(json['consultation_fee'].toString()) ?? 0,
        averageRating: double.tryParse(json['average_rating'].toString()) ?? 0,
        totalReviews: json['total_reviews'],
        waitingTime: json['expected_waiting_time_minutes'],
        profileDescription: json['profile_description'],
      );
}

class FactorScoresModel {
  final double specialtyMatch;
  final double distanceScore;
  final double availabilityScore;
  final double feeScore;
  final double waitingTimeScore;
  final double ratingScore;

  FactorScoresModel({
    required this.specialtyMatch,
    required this.distanceScore,
    required this.availabilityScore,
    required this.feeScore,
    required this.waitingTimeScore,
    required this.ratingScore,
  });

  factory FactorScoresModel.fromJson(Map<String, dynamic> json) => FactorScoresModel(
        specialtyMatch: double.tryParse(json['specialty_match'].toString()) ?? 0,
        distanceScore: double.tryParse(json['distance_score'].toString()) ?? 0,
        availabilityScore: double.tryParse(json['availability_score'].toString()) ?? 0,
        feeScore: double.tryParse(json['fee_score'].toString()) ?? 0,
        waitingTimeScore: double.tryParse(json['waiting_time_score'].toString()) ?? 0,
        ratingScore: double.tryParse(json['rating_score'].toString()) ?? 0,
      );
}

class RecommendationModel {
  final DoctorModel doctor;
  final double distanceKm;
  final String? nextAvailableSlot;
  final double matchScore;
  final FactorScoresModel factorScores;
  final String explanation;

  RecommendationModel({
    required this.doctor,
    required this.distanceKm,
    this.nextAvailableSlot,
    required this.matchScore,
    required this.factorScores,
    required this.explanation,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) => RecommendationModel(
        doctor: DoctorModel.fromJson(json['doctor']),
        distanceKm: double.tryParse(json['distance_km'].toString()) ?? 0,
        nextAvailableSlot: json['next_available_slot'],
        matchScore: double.tryParse(json['overall_match_score'].toString()) ?? 0,
        factorScores: FactorScoresModel.fromJson(json['factor_scores'] ?? {}),
        explanation: json['explanation'] ?? '',
      );
}

class AvailabilityModel {
  final int id;
  final int doctorId;
  final String date;
  final String time;
  final String status;

  AvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) => AvailabilityModel(
        id: json['id'],
        doctorId: json['doctor_id'] ?? 0,
        date: json['available_date'] ?? '',
        time: json['start_time'] ?? '',
        status: json['status'] ?? 'available',
      );
}

class AppointmentModel {
  final int id;
  final int patientId;
  final int? familyMemberId;
  final int doctorId;
  final String date;
  final String time;
  final String? symptoms;
  final String? bookingNotes;
  final String status;

  AppointmentModel({
    required this.id,
    required this.patientId,
    this.familyMemberId,
    required this.doctorId,
    required this.date,
    required this.time,
    this.symptoms,
    this.bookingNotes,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) => AppointmentModel(
        id: json['id'],
        patientId: json['patient_id'] ?? 0,
        familyMemberId: json['family_member_id'],
        doctorId: json['doctor_id'] ?? 0,
        date: json['appointment_date'] ?? '',
        time: json['appointment_time'] ?? '',
        symptoms: json['symptoms'],
        bookingNotes: json['booking_notes'],
        status: json['status'] ?? 'booked',
      );
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'],
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'info',
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'] ?? '',
      );
}
