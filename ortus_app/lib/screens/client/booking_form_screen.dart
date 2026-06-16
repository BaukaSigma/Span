import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/date_picker_helper.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = AppData.trainingSlots.first;
  final TextEditingController _commentController = TextEditingController();

  List<UserData> _trainers = [];
  String? _selectedTrainerId;
  bool _isLoadingTrainers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    try {
      final trainers = await BookingService().getTrainers();
      setState(() {
        _trainers = trainers;
        if (trainers.isNotEmpty) {
          _selectedTrainerId = trainers.first.id;
        }
        _isLoadingTrainers = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrainers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Записаться на тренировку'),
      ),
      body: _isLoadingTrainers
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTrainerCard(),
                  const SizedBox(height: 16),
                  _buildDateTimeCard(),
                  const SizedBox(height: 16),
                  _buildCommentCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Записаться',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrainerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите тренера',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (_trainers.isEmpty)
            const Text(
              'Нет доступных тренеров. Пожалуйста, обратитесь к администрации.',
              style: TextStyle(color: Colors.redAccent),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedTrainerId,
              decoration: const InputDecoration(
                labelText: 'Тренер',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _trainers.map((trainer) {
                return DropdownMenuItem<String>(
                  value: trainer.id,
                  child: Text(trainer.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTrainerId = value);
              },
              validator: (value) => value == null ? 'Выберите тренера' : null,
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дата и время тренировки',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormatter.formatDate(_selectedDate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedSlot,
            decoration: const InputDecoration(
              labelText: 'Временной слот',
              prefixIcon: Icon(Icons.access_time),
            ),
            items: AppData.trainingSlots.map((slot) {
              return DropdownMenuItem<String>(
                value: slot,
                child: Text(slot),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSlot = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Комментарий (необязательно)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Напишите пожелания к тренировке...',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now, // Clients can only book today or in the future
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTrainerId == null) {
      return;
    }

    setState(() => _isSaving = true);
    final booking = await BookingService().createBooking(
      trainerId: _selectedTrainerId!,
      trainingDate: _selectedDate,
      slot: _selectedSlot,
      comment: _commentController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы успешно записались на тренировку!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось записаться. Возможно, вы уже записаны на это время.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
