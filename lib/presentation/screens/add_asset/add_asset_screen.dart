import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/app_user.dart';
import '../../../domain/models/asset.dart';
import '../../../domain/models/asset_activity.dart';
import '../../../domain/models/asset_category.dart';
import '../../../domain/models/asset_status.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/asset/asset_state.dart';
import '../../widgets/primary_button.dart';
import '../../../core/utils/icon_mapper.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key, this.asset});

  final Asset? asset;

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _serialController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _processorController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageTypeController = TextEditingController();
  final _storageBrandController = TextEditingController();
  final _storageCapacityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _assigneeNameController = TextEditingController();

  late final bool _isEditing;
  String? _categoryId;
  AssetStatus _status = AssetStatus.available;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  String? _selectedAssigneeId;
  bool _useCustomAssignee = false;

  Asset? get _editingAsset => widget.asset;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.asset != null;
    final asset = widget.asset;
    if (asset != null) {
      _nameController.text = asset.name;
      _barcodeController.text = asset.barcode;
      _serialController.text = asset.serialNumber;
      _brandController.text = asset.brand ?? '';
      _modelController.text = asset.model ?? '';
      _processorController.text = asset.processorName ?? '';
      _ramController.text = asset.ramCapacity ?? '';
      _storageTypeController.text = asset.storageType ?? '';
      _storageBrandController.text = asset.storageBrand ?? '';
      _storageCapacityController.text = asset.storageCapacity ?? '';
      _departmentController.text = asset.department;
      _locationController.text = asset.location ?? '';
      _priceController.text = asset.purchasePrice != null
          ? asset.purchasePrice!.toString()
          : '0';
      _notesController.text = asset.notes ?? '';
      _categoryId = asset.categoryId;
      _status = asset.status;
      _purchaseDate = asset.purchaseDate;
      _warrantyExpiry = asset.warrantyExpiry;
      _selectedAssigneeId = asset.custodianId;
      if (asset.custodianId == null &&
          (asset.assignedTo != null && asset.assignedTo!.trim().isNotEmpty)) {
        _useCustomAssignee = true;
        _assigneeNameController.text = asset.assignedTo!;
      }
    } else {
      _barcodeController.text = _generateBarcodeValue();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _serialController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _processorController.dispose();
    _ramController.dispose();
    _storageTypeController.dispose();
    _storageBrandController.dispose();
    _storageCapacityController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _assigneeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uuid = const Uuid();

    return BlocBuilder<AssetCubit, AssetState>(
      builder: (context, state) {
        final categories = state.categories;
        final users = state.users;
        if (_categoryId == null && categories.isNotEmpty) {
          _categoryId = categories.first.id;
        }
        AssetCategory? selectedCategory;
        if (_categoryId != null) {
          for (final category in categories) {
            if (category.id == _categoryId) {
              selectedCategory = category;
              break;
            }
          }
        }
        final showSpecFields = () {
          final category = selectedCategory;
          if (category == null) return false;
          final lower = category.name.toLowerCase();
          return lower.contains('laptop') || lower.contains('desktop');
        }();

        AppUser? assignedUser;
        if (!_useCustomAssignee && _selectedAssigneeId != null) {
          for (final user in users) {
            if (user.id == _selectedAssigneeId) {
              assignedUser = user;
              break;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(_isEditing ? 'Edit Asset' : 'Add New Asset'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth > 640 ? 32.0 : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ignore: deprecated_member_use
                      DropdownButtonFormField<String>(
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Row(
                                  children: [
                                    Icon(iconForCategory(category.iconName)),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        // ignore: deprecated_member_use
                        value: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Asset Type',
                        ),
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                        validator: (value) =>
                            value == null ? 'Select asset type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Asset Name',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter asset name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (showSpecFields) ...[
                        Text(
                          'Spesifikasi Perangkat',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _processorController,
                          decoration: const InputDecoration(
                            labelText: 'Processor',
                            hintText: 'Contoh: Intel Core i7-1255U',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ramController,
                          decoration: const InputDecoration(
                            labelText: 'RAM',
                            hintText: 'Contoh: 16 GB DDR4',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _storageTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Tipe Storage',
                            hintText: 'Contoh: SSD NVMe / HDD',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _storageBrandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand Storage',
                            hintText: 'Contoh: Samsung / Seagate',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _storageCapacityController,
                          decoration: const InputDecoration(
                            labelText: 'Kapasitas Storage',
                            hintText: 'Contoh: 512 GB',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _barcodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Barcode Asset',
                          suffixIcon: IconButton(
                            onPressed: _regenerateBarcode,
                            icon: const Icon(Icons.refresh_outlined),
                            tooltip: 'Generate barcode',
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Masukkan kode barcode';
                          }
                          if (trimmed.length < 4) {
                            return 'Barcode terlalu pendek';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _serialController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter serial number'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Purchase Date',
                              value: _purchaseDate,
                              onTap: () async {
                                final date = await _pickDate(
                                  context,
                                  _purchaseDate,
                                );
                                if (date != null) {
                                  setState(() => _purchaseDate = date);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Price',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DateField(
                        label: 'Warranty Expiry',
                        value: _warrantyExpiry,
                        onTap: () async {
                          final date = await _pickDate(
                            context,
                            _warrantyExpiry,
                          );
                          if (date != null) {
                            setState(() => _warrantyExpiry = date);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // ignore: deprecated_member_use
                      DropdownButtonFormField<AssetStatus>(
                        // ignore: deprecated_member_use
                        value: _status,
                        items: AssetStatus.values
                            .where((status) => status != AssetStatus.all)
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Status'),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        value: _useCustomAssignee,
                        title: const Text('Manual Assign To'),
                        subtitle: const Text(
                          'Masukkan nama penerima jika tidak ada di daftar user',
                        ),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _useCustomAssignee = value;
                            if (value) {
                              _selectedAssigneeId = null;
                            } else {
                              _assigneeNameController.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_useCustomAssignee)
                        TextFormField(
                          controller: _assigneeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Assign To (Name)',
                            hintText: 'Contoh: Tim Finance',
                          ),
                          validator: (value) {
                            if (_useCustomAssignee) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Masukkan nama penerima';
                              }
                            }
                            return null;
                          },
                        )
                      else
                        _AssigneeField(
                          label: 'Assign To',
                          user: assignedUser,
                          enabled: users.isNotEmpty,
                          onTap: users.isEmpty
                              ? null
                              : () async {
                                  final result = await _showAssigneePicker(
                                    context: context,
                                    users: users,
                                    selected: assignedUser,
                                  );
                                  if (!mounted) return;
                                  setState(
                                    () => _selectedAssigneeId = result?.id,
                                  );
                                },
                          onClear: assignedUser != null
                              ? () => setState(() => _selectedAssigneeId = null)
                              : null,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                      ),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isEditing ? 'Save Changes' : 'Add Asset',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_categoryId == null) return;

                          final department = _departmentController.text.trim();
                          final location = _locationController.text.trim();
                          final brand = _brandController.text.trim();
                          final model = _modelController.text.trim();
                          final processor = _processorController.text.trim();
                          final ram = _ramController.text.trim();
                          final storageType = _storageTypeController.text
                              .trim();
                          final storageBrand = _storageBrandController.text
                              .trim();
                          final storageCapacity = _storageCapacityController
                              .text
                              .trim();
                          final notes = _notesController.text.trim();
                          final barcode = _barcodeController.text
                              .trim()
                              .toUpperCase();
                          if (barcode != _barcodeController.text) {
                            _barcodeController.value = _barcodeController.value
                                .copyWith(
                                  text: barcode,
                                  selection: TextSelection.collapsed(
                                    offset: barcode.length,
                                  ),
                                );
                          }
                          final price =
                              double.tryParse(
                                _priceController.text.replaceAll(',', ''),
                              ) ??
                              0;
                          AppUser? selectedUser;
                          if (!_useCustomAssignee &&
                              _selectedAssigneeId != null) {
                            for (final user in users) {
                              if (user.id == _selectedAssigneeId) {
                                selectedUser = user;
                                break;
                              }
                            }
                          }
                          final customAssigneeName = _useCustomAssignee
                              ? _assigneeNameController.text.trim()
                              : null;
                          final assigneeName = _useCustomAssignee
                              ? customAssigneeName
                              : selectedUser?.name;
                          final effectiveAssigneeName =
                              assigneeName ?? (_isEditing ? '' : null);
                          final custodianId = _useCustomAssignee
                              ? null
                              : selectedUser?.id;
                          final specEnabled = showSpecFields;
                          final cubit = context.read<AssetCubit>();

                          if (_isEditing && _editingAsset != null) {
                            final base = _editingAsset!;
                            final updated = base.copyWith(
                              name: _nameController.text.trim(),
                              barcode: barcode,
                              serialNumber: _serialController.text.trim(),
                              categoryId: _categoryId,
                              status: _status,
                              department: department.isEmpty
                                  ? base.department
                                  : department,
                              assignedTo: effectiveAssigneeName,
                              custodianId: custodianId,
                              location: location.isEmpty ? null : location,
                              brand: brand.isEmpty ? null : brand,
                              model: model.isEmpty ? null : model,
                              processorName: specEnabled
                                  ? (processor.isEmpty ? null : processor)
                                  : base.processorName,
                              ramCapacity: specEnabled
                                  ? (ram.isEmpty ? null : ram)
                                  : base.ramCapacity,
                              storageType: specEnabled
                                  ? (storageType.isEmpty ? null : storageType)
                                  : base.storageType,
                              storageBrand: specEnabled
                                  ? (storageBrand.isEmpty ? null : storageBrand)
                                  : base.storageBrand,
                              storageCapacity: specEnabled
                                  ? (storageCapacity.isEmpty
                                        ? null
                                        : storageCapacity)
                                  : base.storageCapacity,
                              purchaseDate: _purchaseDate,
                              purchasePrice: price,
                              warrantyExpiry: _warrantyExpiry,
                              notes: notes.isEmpty ? null : notes,
                            );
                            await cubit.updateAsset(updated);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            return;
                          }

                          final asset = Asset(
                            id: 'asset_${uuid.v4()}',
                            name: _nameController.text.trim(),
                            barcode: barcode,
                            serialNumber: _serialController.text.trim(),
                            categoryId: _categoryId!,
                            status: _status,
                            department: department.isEmpty
                                ? 'Unassigned'
                                : department,
                            assignedTo: effectiveAssigneeName,
                            custodianId: custodianId,
                            processorName: specEnabled
                                ? (processor.isEmpty ? null : processor)
                                : null,
                            ramCapacity: specEnabled
                                ? (ram.isEmpty ? null : ram)
                                : null,
                            storageType: specEnabled
                                ? (storageType.isEmpty ? null : storageType)
                                : null,
                            storageBrand: specEnabled
                                ? (storageBrand.isEmpty ? null : storageBrand)
                                : null,
                            storageCapacity: specEnabled
                                ? (storageCapacity.isEmpty
                                      ? null
                                      : storageCapacity)
                                : null,
                            location: location.isEmpty ? null : location,
                            brand: brand.isEmpty ? null : brand,
                            model: model.isEmpty ? null : model,
                            purchaseDate: _purchaseDate,
                            purchasePrice: price,
                            warrantyExpiry: _warrantyExpiry,
                            notes: notes.isEmpty ? null : notes,
                            createdAt: DateTime.now(),
                          );

                          await cubit.addAsset(
                            asset,
                            activity: AssetActivity(
                              id: 'activity_${uuid.v4()}',
                              assetId: asset.id,
                              title: 'New asset added',
                              description: '${asset.name} added to inventory',
                              timestamp: DateTime.now(),
                            ),
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _generateBarcodeValue() {
    final raw = const Uuid().v4().replaceAll('-', '').toUpperCase();
    final segmentLength = raw.length >= 10 ? 10 : raw.length;
    final segment = raw.substring(0, segmentLength);
    return 'AS-$segment';
  }

  void _regenerateBarcode() {
    final generated = _generateBarcodeValue();
    setState(() {
      _barcodeController.text = generated;
    });
  }

  Future<AppUser?> _showAssigneePicker({
    required BuildContext context,
    required List<AppUser> users,
    AppUser? selected,
  }) async {
    if (users.isEmpty) {
      return null;
    }

    return showModalBottomSheet<AppUser?>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AssigneePickerSheet(users: users, initialSelected: selected),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 30);
    final lastDate = DateTime(now.year + 20);

    DateTime initialDate = initial ?? now;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    return picked;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final text = value == null ? 'dd/mm/yyyy' : formatter.format(value!);
    final theme = Theme.of(context);
    final isPlaceholder = value == null;

    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPlaceholder ? const Color(0xFF9CA3AF) : null,
          ),
        ),
      ),
    );
  }
}

class _AssigneeField extends StatelessWidget {
  const _AssigneeField({
    required this.label,
    required this.user,
    required this.enabled,
    this.onTap,
    this.onClear,
  });

  final String label;
  final AppUser? user;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = user?.name ?? 'Tidak ada pemegang';
    final isPlaceholder = user == null;
    final showDisabledState = !enabled && user == null;

    Widget? suffixIcon;
    if (user != null) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Hapus pemegang',
        onPressed: onClear,
      );
    } else if (enabled) {
      suffixIcon = const Icon(Icons.arrow_drop_down);
    } else {
      suffixIcon = const Icon(
        Icons.person_off_outlined,
        color: Color(0xFF9CA3AF),
      );
    }

    final decorator = InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        enabled: enabled || user != null,
        helperText: showDisabledState
            ? 'Tidak ada pengguna yang bisa ditugaskan'
            : null,
        suffixIcon: suffixIcon,
      ),
      child: Text(
        displayText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: showDisabledState
              ? theme.disabledColor
              : isPlaceholder
              ? const Color(0xFF9CA3AF)
              : null,
        ),
      ),
    );

    if (!enabled || onTap == null) {
      return decorator;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: decorator,
    );
  }
}

class _AssigneePickerSheet extends StatefulWidget {
  const _AssigneePickerSheet({required this.users, this.initialSelected});

  final List<AppUser> users;
  final AppUser? initialSelected;

  @override
  State<_AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends State<_AssigneePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = widget.users.where((user) {
      if (query.isEmpty) return true;
      final name = user.name.toLowerCase();
      final email = user.email.toLowerCase();
      final department = user.departmentCode.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          department.contains(query);
    }).toList();

    final hasResults = filtered.isNotEmpty;
    final itemCount = hasResults ? filtered.length + 1 : 2;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari pengguna',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: itemCount,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.person_off_outlined),
                      title: const Text('Tidak ada pemegang'),
                      trailing: widget.initialSelected == null
                          ? const Icon(Icons.check, color: Colors.black)
                          : null,
                      onTap: () => Navigator.of(context).pop(null),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                    );
                  }

                  if (!hasResults && index == 1) {
                    final trimmedQuery = _query.trim();
                    final message = trimmedQuery.isEmpty
                        ? 'Belum ada pengguna yang tersedia.'
                        : 'Tidak ada pengguna ditemukan untuk "$trimmedQuery".';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }

                  final user = filtered[index - 1];
                  final subtitleParts = <String>[
                    if (user.email.isNotEmpty) user.email,
                    if (user.departmentCode.isNotEmpty) user.departmentCode,
                  ];
                  final subtitleText = subtitleParts.join(' | ');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE5E7EB),
                      child: Text(
                        _initialsFor(user.name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: subtitleText.isEmpty
                        ? null
                        : Text(
                            subtitleText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                    trailing: widget.initialSelected?.id == user.id
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () => Navigator.of(context).pop(user),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed
        .split(RegExp(r'\\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    final first = parts.first[0].toUpperCase();
    if (parts.length == 1) {
      return first;
    }

    final second = parts[1][0].toUpperCase();
    return '$first$second';
  }
}
