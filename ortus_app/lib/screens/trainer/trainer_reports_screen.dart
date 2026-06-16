import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class TrainerReportsScreen extends StatefulWidget {
  const TrainerReportsScreen({super.key});

  @override
  State<TrainerReportsScreen> createState() => _TrainerReportsScreenState();
}

class _TrainerReportsScreenState extends State<TrainerReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = AppData.trainingSlots.first;
  final TextEditingController _commentController = TextEditingController();
  final List<PlatformFile> _attachments = [];
  bool _isSubmitting = false;
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = ReportService().getMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Отчёты'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
            tabs: const [
              Tab(text: 'Новый отчёт'),
              Tab(text: 'Мои отчёты'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateTab(),
            _buildMyReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 16),
        _buildAttachmentsCard(),
        const SizedBox(height: 16),
        _buildCommentCard(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Отправить отчёт',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
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
            'Данные тренировки',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormatter.formatDate(_selectedDate)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedSlot,
            items: AppData.trainingSlots
                .map(
                  (slot) => DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedSlot = value);
            },
            decoration: const InputDecoration(labelText: 'Слот тренировки'),
          ),
          const SizedBox(height: 12),
          Text(
            'Отправка доступна за 60–30 минут до начала тренировки.',
            style: TextStyle(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Вложения (до 4 файлов)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _pickAttachments,
                icon: const Icon(Icons.attach_file),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Форматы: jpg, png, pdf, docx',
            style: TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          if (_attachments.isEmpty)
            Text('Файлы не выбраны', style: TextStyle(color: AppColors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Chip(
                  label: Text(file.name),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _attachments.removeAt(index));
                  },
                );
              }).toList(),
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
            'Комментарий',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Например: план тренировки или детали отчёта',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsTab() {
    return FutureBuilder<List<ReportModel>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 72,
                  color: AppColors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text('Отчётов пока нет'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadReports(),
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _TrainerReportCard(
                report: reports[index],
                onDelete: () => _deleteReport(reports[index].id),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
    );
    if (!mounted) return;
    if (result == null) return;

    final files = result.files;

    if (_attachments.length + files.length > 4) {
      final available = 4 - _attachments.length;
      if (available <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Можно добавить максимум 4 файла')),
        );
        return;
      }
      _attachments.addAll(files.take(available));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавлены не все файлы — лимит 4')),
      );
    } else {
      _attachments.addAll(files);
    }

    setState(() {});
  }

  Future<void> _submitReport() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно вложение')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ReportService().createReport(
      trainingDate: _selectedDate,
      slot: _selectedSlot,
      comment: _commentController.text.trim(),
      attachments: _attachments,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (success) {
      _attachments.clear();
      _commentController.clear();
      _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отчёт отправлен'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить отчёт')),
      );
    }
  }

  Future<void> _deleteReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отчёт?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ReportService().deleteReport(id);
    if (!mounted) return;

    if (success) {
      _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отчёт удалён')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить отчёт')),
      );
    }
  }
}

class _TrainerReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onDelete;

  const _TrainerReportCard({required this.report, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormatter.formatDate(report.trainingDate)} • ${report.slot}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _LateChip(isLate: report.isLate),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            if (report.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: ${report.comment}'),
            ],
            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.attachments
                    .map((attachment) => Chip(
                          label: Text(attachment.originalName.isEmpty
                              ? 'Файл'
                              : attachment.originalName),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LateChip extends StatelessWidget {
  final bool isLate;
  const _LateChip({required this.isLate});

  @override
  Widget build(BuildContext context) {
    final color = isLate ? Colors.redAccent : Colors.green;
    final label = isLate ? 'Опоздал' : 'В срок';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
