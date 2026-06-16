import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class TrainerBookingsScreen extends StatefulWidget {
  const TrainerBookingsScreen({super.key});

  @override
  State<TrainerBookingsScreen> createState() => _TrainerBookingsScreenState();
}

class _TrainerBookingsScreenState extends State<TrainerBookingsScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = BookingService().getTrainerBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Записи клиентов'),
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
                    Icons.event_busy_outlined,
                    size: 72,
                    color: AppColors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'К вам пока никто не записался',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                return _TrainerBookingCard(
                  booking: bookings[index],
                  onConfirm: () => _confirmBooking(bookings[index].id),
                  onCancel: () => _cancelBooking(bookings[index].id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmBooking(String id) async {
    final success = await BookingService().confirmBooking(id);
    if (!mounted) return;

    if (success) {
      _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись успешно подтверждена'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось подтвердить запись')),
      );
    }
  }

  Future<void> _cancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить запись?'),
        content: const Text('Вы действительно хотите отменить тренировку с учеником?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Назад'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Отклонить'),
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

class _TrainerBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _TrainerBookingCard({
    required this.booking,
    required this.onConfirm,
    required this.onCancel,
  });

  String _cleanPhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8') && digits.length == 11) {
      digits = '7${digits.substring(1)}';
    }
    if (digits.length == 10) {
      digits = '7$digits';
    }
    return digits;
  }

  Future<void> _launchWhatsApp() async {
    final phone = _cleanPhone(booking.clientPhone);
    final dateStr = DateFormatter.formatDate(booking.trainingDate);
    final message = Uri.encodeComponent(
      'Здравствуйте, ${booking.clientName}! Вы записаны ко мне на тренировку $dateStr в ${booking.slot}. Все в силе?',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp url: $url');
    }
  }

  Future<void> _launchCall() async {
    final phone = _cleanPhone(booking.clientPhone);
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch phone call url: $url');
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
                    'Ученик: ${booking.clientName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Телефон ученика: ${booking.clientPhone}', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 8),
            Text(
              'Дата: ${DateFormatter.formatDate(booking.trainingDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Слот времени: ${booking.slot}'),
            if (booking.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: "${booking.comment}"', style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic)),
            ],
            const Divider(height: 24),
            Row(
              children: [
                IconButton(
                  onPressed: _launchCall,
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  tooltip: 'Позвонить',
                ),
                IconButton(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.message, color: Colors.green),
                  tooltip: 'WhatsApp',
                ),
                const Spacer(),
                if (booking.isPending) ...[
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Отклонить'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Подтвердить', style: TextStyle(color: AppColors.white)),
                  ),
                ] else if (booking.isConfirmed) ...[
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Отменить тренировку'),
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
