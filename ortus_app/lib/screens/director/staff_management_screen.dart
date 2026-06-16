import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String _roleFilter = '';
  late Future<List<UserData>> _staffFuture;

  final List<Map<String, String>> _roles = const [
    {'key': '', 'label': 'Все'},
    {'key': 'manager', 'label': 'Менеджеры'},
    {'key': 'trainer', 'label': 'Тренеры'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _staffFuture = UserService().getStaff(
        role: _roleFilter.isEmpty ? null : _roleFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _openCreateStaff,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<UserData>>(
              future: _staffFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final staff = snapshot.data ?? [];
                if (staff.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 72,
                          color: AppColors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text('Сотрудников пока нет'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _StaffCard(
                        user: staff[index],
                        onUpdated: _load,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _roles.map((role) {
          final key = role['key'] ?? '';
          final label = role['label'] ?? '';
          final isSelected = key == _roleFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _roleFilter = key);
                _load();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w600,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openCreateStaff() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _CreateStaffSheet(),
    );

    if (created == true) {
      _load();
    }
  }
}

class _CreateStaffSheet extends StatefulWidget {
  const _CreateStaffSheet();

  @override
  State<_CreateStaffSheet> createState() => _CreateStaffSheetState();
}

class _CreateStaffSheetState extends State<_CreateStaffSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'trainer';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новый сотрудник',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ФИО'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Телефон'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Роль'),
              items: const [
                DropdownMenuItem(
                  value: 'trainer',
                  child: Text('Тренер'),
                ),
                DropdownMenuItem(
                  value: 'manager',
                  child: Text('Менеджер'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                        'Создать',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля сотрудника')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final created = await UserService().createStaff(
      phoneNumber: _phoneController.text.trim(),
      fullName: _nameController.text.trim(),
      password: _passwordController.text.trim(),
      role: _role,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (created != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать сотрудника')),
      );
    }
  }
}

class _StaffCard extends StatelessWidget {
  final UserData user;
  final VoidCallback onUpdated;

  const _StaffCard({required this.user, required this.onUpdated});

  String get roleLabel {
    switch (user.role) {
      case 'manager':
        return 'Менеджер';
      case 'trainer':
        return 'Тренер';
      case 'director':
        return 'Директор';
      default:
        return 'Клиент';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = user.status ?? 'active';
    final isActive = status == 'active';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(user.phoneNumber, style: TextStyle(color: AppColors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Badge(label: roleLabel),
                      _Badge(
                        label: isActive ? 'Активен' : 'Неактивен',
                        color: isActive ? Colors.green : Colors.redAccent,
                      ),
                    ],
                  ),
                  if (user.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Создан: ${DateFormatter.formatDate(user.createdAt!)}',
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
             PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'status':
                    final updated = await UserService().updateStaffStatus(
                      userId: user.id,
                      status: isActive ? 'inactive' : 'active',
                    );
                    if (updated != null && context.mounted) {
                      onUpdated();
                    }
                    break;
                  case 'delete':
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Удалить сотрудника?'),
                        content: const Text('Действие нельзя отменить.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Отмена'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final success = await UserService().deleteStaff(user.id);
                      if (success && context.mounted) {
                        onUpdated();
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'status',
                  child: Text(isActive ? 'Сделать неактивным' : 'Активировать'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
