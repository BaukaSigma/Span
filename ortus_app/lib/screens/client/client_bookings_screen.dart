import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import 'booking_form_screen.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = BookingService().getClientBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои записи на тренировки'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 72,
                    color: AppColors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'У вас пока нет записей',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openBookingForm,
                    child: const Text('Записаться сейчас', style: TextStyle(color: AppColors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadBookings(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _BookingCard(
                  booking: bookings[index],
                  onCancel: () => _cancelBooking(bookings[index].id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openBookingForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Future<void> _openBookingForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingFormScreen()),
    );
    if (result == true) {
      _loadBookings();
    }
  }

  Future<void> _cancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить запись?'),
        content: const Text('Вы действительно хотите отменить запись на тренировку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Назад'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Отменить запись'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await BookingService().cancelBooking(id);
    if (!mounted) return;

    if (success) {
      _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись успешно отменена')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отменить запись')),
      );
    }
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;

  const _BookingCard({required this.booking, required this.onCancel});

  String _cleanPhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8') && digits.length == 11) {
      digits = '7${digits.substring(1)}';
    }
    // If it doesn't start with code but is 10 digits (e.g. 7071234567), prepends 7
    if (digits.length == 10) {
      digits = '7$digits';
    }
    return digits;
  }

  Future<void> _launchWhatsApp() async {
    final phone = _cleanPhone(booking.trainerPhone);
    final dateStr = DateFormatter.formatDate(booking.trainingDate);
    final message = Uri.encodeComponent(
      'Здравствуйте, ${booking.trainerName}! Я записался к вам на тренировку $dateStr в ${booking.slot}. Подтвердите, пожалуйста.',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp url: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Тренер: ${booking.trainerName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Телефон тренера: ${booking.trainerPhone}', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 8),
            Text(
              'Дата: ${DateFormatter.formatDate(booking.trainingDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Слот времени: ${booking.slot}'),
            if (booking.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ваш комментарий: "${booking.comment}"', style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic)),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!booking.isCancelled) ...[
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                    label: const Text('Отменить', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.message, color: AppColors.white, size: 20),
                    label: const Text('WhatsApp', style: TextStyle(color: AppColors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = 'Подтверждено';
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = 'Отменено';
        break;
      default:
        color = Colors.orange;
        label = 'Ожидает';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
