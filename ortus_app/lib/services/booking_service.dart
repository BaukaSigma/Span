import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';
import '../models/user_data.dart';
import 'auth_service.dart';

class BookingService {
  Future<List<UserData>> getTrainers() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.usersUrl}/trainers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => UserData.fromJson(e)).toList();
    }
    return [];
  }

  Future<BookingModel?> createBooking({
    required String trainerId,
    required DateTime trainingDate,
    required String slot,
    required String comment,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse(ApiConfig.bookingsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'trainerId': trainerId,
        'trainingDate': trainingDate.toIso8601String(),
        'slot': slot,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      return BookingModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<List<BookingModel>> getClientBookings() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.bookingsUrl}/client'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<BookingModel>> getTrainerBookings() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.bookingsUrl}/trainer'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> cancelBooking(String bookingId) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('${ApiConfig.bookingsUrl}/$bookingId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> confirmBooking(String bookingId) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('${ApiConfig.bookingsUrl}/$bookingId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}
