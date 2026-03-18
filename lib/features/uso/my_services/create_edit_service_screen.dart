// create_edit_service_screen.dart
// Reziphay — USO: Create or Edit a Service
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../models/category.dart';
import '../../../services/discovery_service.dart';

// ── Enums ───────────────────────────────────────────────────────────────────

enum _ServiceType { solo, multi }
enum _ApprovalMode { manual, auto }

// ── Brand mini-model ────────────────────────────────────────────────────────

class _BrandItem {
  const _BrandItem({required this.id, required this.name});
  final String id;
  final String name;

  factory _BrandItem.fromJson(Map<String, dynamic> json) =>
      _BrandItem(id: json['id'] as String, name: json['name'] as String);
}

// ── Day-of-week availability row ────────────────────────────────────────────

class _DayRule {
  _DayRule(this.dayOfWeek, this.label);
  final String dayOfWeek; // MONDAY … SUNDAY
  final String label;
  bool enabled = false;
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime   = const TimeOfDay(hour: 18, minute: 0);
}

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ── Screen ──────────────────────────────────────────────────────────────────

class CreateEditServiceScreen extends ConsumerStatefulWidget {
  const CreateEditServiceScreen({super.key, this.serviceId});

  /// null → create mode, non-null → edit mode
  final String? serviceId;

  @override
  ConsumerState<CreateEditServiceScreen> createState() =>
      _CreateEditServiceScreenState();
}

class _CreateEditServiceScreenState
    extends ConsumerState<CreateEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();

  // Pricing
  final _priceCtrl       = TextEditingController();
  String _currency       = 'AZN';

  // Booking
  _ServiceType  _serviceType  = _ServiceType.solo;
  _ApprovalMode _approvalMode = _ApprovalMode.manual;
  final _waitingCtrl     = TextEditingController(text: '15');
  final _minAdvCtrl      = TextEditingController();
  final _maxAdvCtrl      = TextEditingController();
  final _cancelCtrl      = TextEditingController();

  // Brand & Category
  String?      _selectedBrandId;
  String?      _selectedBrandName;
  String?      _selectedCategoryId;
  String?      _selectedCategoryName;

  // Availability schedule
  final List<_DayRule> _days = [
    _DayRule('MONDAY',    'Mon'),
    _DayRule('TUESDAY',   'Tue'),
    _DayRule('WEDNESDAY', 'Wed'),
    _DayRule('THURSDAY',  'Thu'),
    _DayRule('FRIDAY',    'Fri'),
    _DayRule('SATURDAY',  'Sat'),
    _DayRule('SUNDAY',    'Sun'),
  ];

  // Photo
  File?   _pickedImage;
  String? _existingPhotoId;
  String? _existingPhotoUrl;
  bool    _removePhoto = false;

  // State
  bool _loading    = false;
  bool _loadingInit = false;
  List<_BrandItem> _brands     = [];
  List<CategoryItem> _categories = [];

  bool get _isEdit => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    _loadPickerData();
    if (_isEdit) _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _waitingCtrl.dispose();
    _minAdvCtrl.dispose();
    _maxAdvCtrl.dispose();
    _cancelCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadPickerData() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get<Map<String, dynamic>>(
          Endpoints.myBrands,
          fromJson: (j) => j,
        ),
        DiscoveryService.instance.fetchCategories(),
      ]);

      final brandsJson = results[0] as Map<String, dynamic>;
      final cats       = results[1] as List<CategoryItem>;

      final items = (brandsJson['items'] as List<dynamic>? ?? [])
          .map((e) => _BrandItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() {
        _brands     = items;
        _categories = cats;
      });
    } catch (_) {
      // non-critical — pickers just stay empty
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingInit = true);
    try {
      final json = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.serviceById(widget.serviceId!),
        fromJson: (j) => j,
      );
      if (!mounted) return;
      // Backend returns { "service": { ... } } — unwrap before populating
      final service = (json['service'] as Map<String, dynamic>?) ?? json;
      _populateFromJson(service);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not load service data.');
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  void _populateFromJson(Map<String, dynamic> json) {
    _nameCtrl.text     = json['name']        as String? ?? '';
    _descCtrl.text     = json['description'] as String? ?? '';
    _locationCtrl.text = json['location']    as String? ?? '';
    _priceCtrl.text = json['priceAmount'] != null
        ? json['priceAmount'].toString()
        : '';
    _currency = json['priceCurrency'] as String? ?? 'AZN';

    _serviceType  = (json['serviceType'] as String?) == 'MULTI'
        ? _ServiceType.multi : _ServiceType.solo;
    _approvalMode = (json['approvalMode'] as String?) == 'AUTO'
        ? _ApprovalMode.auto : _ApprovalMode.manual;

    _waitingCtrl.text = (json['waitingTimeMinutes'] ?? 15).toString();
    _minAdvCtrl.text  = json['minAdvanceMinutes']?.toString() ?? '';
    _maxAdvCtrl.text  = json['maxAdvanceMinutes']?.toString() ?? '';
    _cancelCtrl.text  = json['freeCancellationDeadlineMinutes']?.toString() ?? '';

    final brand    = json['brand']    as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    if (brand != null) {
      _selectedBrandId   = brand['id']   as String?;
      _selectedBrandName = brand['name'] as String?;
    }
    if (category != null) {
      _selectedCategoryId   = category['id']   as String?;
      _selectedCategoryName = category['name'] as String?;
    }

    // Existing photo
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final first = photos.first as Map<String, dynamic>;
      _existingPhotoId  = first['id'] as String?;
      final file        = first['file'] as Map<String, dynamic>?;
      _existingPhotoUrl = file?['url'] as String?;
    }

    // Availability rules — backend nests them under availability.rules
    final availability = json['availability'] as Map<String, dynamic>?;
    final rules = (availability?['rules'] ?? json['availabilityRules'])
            as List<dynamic>? ??
        [];
    for (final r in rules) {
      final m   = r as Map<String, dynamic>;
      final dow = m['dayOfWeek'] as String;
      final day = _days.firstWhere(
        (d) => d.dayOfWeek == dow,
        orElse: () => _days[0],
      );
      if (_days.contains(day)) {
        day.enabled   = m['isActive'] as bool? ?? true;
        final start   = (m['startTime'] as String? ?? '09:00').split(':');
        final end     = (m['endTime']   as String? ?? '18:00').split(':');
        day.startTime = TimeOfDay(
          hour:   int.tryParse(start[0]) ?? 9,
          minute: int.tryParse(start[1]) ?? 0,
        );
        day.endTime = TimeOfDay(
          hour:   int.tryParse(end[0]) ?? 18,
          minute: int.tryParse(end[1]) ?? 0,
        );
      }
    }

    setState(() {});
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final waitingInt = int.tryParse(_waitingCtrl.text.trim()) ?? 15;

      final body = <String, dynamic>{
        'name':                            _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description':                   _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        if (_selectedBrandId != null)
          'brandId':                       _selectedBrandId,
        if (_selectedCategoryId != null)
          'categoryId':                    _selectedCategoryId,
        if (_priceCtrl.text.trim().isNotEmpty) ...{
          'priceAmount':  double.tryParse(_priceCtrl.text.trim()),
          'priceCurrency': _currency,
        },
        'waitingTimeMinutes':              waitingInt,
        if (_minAdvCtrl.text.trim().isNotEmpty)
          'minAdvanceMinutes':             int.tryParse(_minAdvCtrl.text.trim()),
        if (_maxAdvCtrl.text.trim().isNotEmpty)
          'maxAdvanceMinutes':             int.tryParse(_maxAdvCtrl.text.trim()),
        if (_cancelCtrl.text.trim().isNotEmpty)
          'freeCancellationDeadlineMinutes': int.tryParse(_cancelCtrl.text.trim()),
        'serviceType':                     _serviceType == _ServiceType.multi ? 'MULTI' : 'SOLO',
        'approvalMode':                    _approvalMode == _ApprovalMode.auto ? 'AUTO' : 'MANUAL',
        'availabilityRules': _days
            .where((d) => d.enabled)
            .map((d) => {
                  'dayOfWeek': d.dayOfWeek,
                  'startTime': _fmtTime(d.startTime),
                  'endTime':   _fmtTime(d.endTime),
                  'isActive':  true,
                })
            .toList(),
      };

      String serviceId;

      if (_isEdit) {
        await ApiClient.instance.patch<Map<String, dynamic>>(
          Endpoints.updateService(widget.serviceId!),
          data:     body,
          fromJson: (j) => j,
        );
        serviceId = widget.serviceId!;
      } else {
        final result = await ApiClient.instance.post<Map<String, dynamic>>(
          Endpoints.createService,
          data:     body,
          fromJson: (j) => j,
        );
        // Backend returns { "service": { "id": "..." } }
        final created = result['service'] as Map<String, dynamic>?;
        serviceId = (created?['id'] as String?) ?? '';
      }

      // ── Photo handling ────────────────────────────────────────────────────
      if (serviceId.isNotEmpty) {
        // Remove existing photo if user deleted or replaced it
        if (_existingPhotoId != null && (_removePhoto || _pickedImage != null)) {
          await ApiClient.instance.deleteVoid(
            Endpoints.deleteServicePhoto(serviceId, _existingPhotoId!),
          );
        }
        // Upload new photo
        if (_pickedImage != null) {
          await ApiClient.instance.postMultipart(
            Endpoints.servicePhotos(serviceId),
            file: _pickedImage!,
          );
        }
      }

      if (!mounted) return;
      context.pop(true); // signal refresh
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppPalette.error),
    );
  }

  Future<void> _pickTime(
    _DayRule day,
    bool isStart,
  ) async {
    final initial = isStart ? day.startTime : day.endTime;
    final picked  = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        day.startTime = picked;
      } else {
        day.endTime = picked;
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Step 1: pick from source
      final picker = ImagePicker();
      final xfile  = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (xfile == null || !mounted) return;

      // Step 2: crop to 1:1 square
      final primary = context.palette.primary;
      final cropped = await ImageCropper().cropImage(
        sourcePath: xfile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: primary,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (cropped == null || !mounted) return;

      setState(() {
        _pickedImage = File(cropped.path);
        _removePhoto = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final msg = e.code == 'camera_access_denied'
          ? l10n.cameraAccessDenied
          : e.code == 'photo_access_denied'
              ? l10n.photoLibraryAccessDenied
              : 'Could not open ${source == ImageSource.camera ? 'camera' : 'photo library'}.';
      _showError(msg);
    }
  }

  Future<void> _showPhotoOptions() async {
    // Check camera availability (not available on iOS Simulator)
    final cameraAvailable = await ImagePicker().supportsImageSource(
      ImageSource.camera,
    );

    if (!mounted) return;

    final sheetBg = context.dc.background;
    final dragColor = context.dc.divider;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: dragColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (cameraAvailable)
                ListTile(
                  leading: const Icon(Iconsax.camera),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickPhoto(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_pickedImage != null ||
                  (_existingPhotoUrl != null && !_removePhoto))
                ListTile(
                  leading: const Icon(
                    Iconsax.trash,
                    color: AppPalette.error,
                  ),
                  title: Text(
                    context.l10n.removePhoto,
                    style: const TextStyle(color: AppPalette.error),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pickedImage = null;
                      _removePhoto = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = context.palette.primary;

    final dc = context.dc;

    if (_loadingInit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? l10n.editService : l10n.newService),
          backgroundColor: dc.background,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.editService : l10n.newService,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: dc.textPrimary,
          ),
        ),
        backgroundColor: dc.background,
        foregroundColor: dc.textPrimary,
        elevation: 0,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                _isEdit ? l10n.save : l10n.create,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primary,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Service Photo ─────────────────────────────────────────────
            _SectionHeader(title: l10n.servicePhoto, icon: Iconsax.image),
            _PhotoPicker(
              pickedImage:      _pickedImage,
              existingPhotoUrl: _removePhoto ? null : _existingPhotoUrl,
              onTap:            _showPhotoOptions,
            ),

            const SizedBox(height: 16),

            // ── Basic Info ────────────────────────────────────────────────
            _SectionHeader(title: l10n.basicInfo, icon: Iconsax.document_text),
            _FieldCard(children: [
              _FormField(
                controller: _nameCtrl,
                label: l10n.serviceName.toUpperCase(),
                hint: l10n.serviceNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _descCtrl,
                label: l10n.descriptionLabel.toUpperCase(),
                hint: l10n.descriptionHint,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _locationCtrl,
                label: l10n.location.toUpperCase(),
                hint: 'e.g. Bakı, Neftçilər pr.',
              ),
            ]),

            const SizedBox(height: 16),

            // ── Brand & Category ──────────────────────────────────────────
            _SectionHeader(title: l10n.brandDetailLabel, icon: Iconsax.briefcase),
            _FieldCard(children: [
              _PickerRow(
                label: l10n.brandLabel.toUpperCase(),
                value: _selectedBrandName ?? l10n.none,
                onTap: _brands.isEmpty ? null : _pickBrand,
                trailing: _selectedBrandId != null
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _selectedBrandId   = null;
                          _selectedBrandName = null;
                        }),
                        child: Icon(Icons.close, size: 18,
                            color: context.dc.textTertiary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              _PickerRow(
                label: l10n.categoryLabel.toUpperCase(),
                value: _selectedCategoryName ?? l10n.none,
                onTap: _categories.isEmpty ? null : _pickCategory,
                trailing: _selectedCategoryId != null
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategoryId   = null;
                          _selectedCategoryName = null;
                        }),
                        child: Icon(Icons.close, size: 18,
                            color: context.dc.textTertiary),
                      )
                    : null,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Pricing ───────────────────────────────────────────────────
            _SectionHeader(title: l10n.pricingSection, icon: Iconsax.money),
            _FieldCard(children: [
              _PriceRow(
                controller: _priceCtrl,
                currency: _currency,
                onCurrencyChange: (v) => setState(() => _currency = v),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Booking Settings ──────────────────────────────────────────
            _SectionHeader(title: l10n.bookingSettings, icon: Iconsax.setting),
            _FieldCard(children: [
              _ToggleRow<_ServiceType>(
                label: l10n.serviceType.toUpperCase(),
                value: _serviceType,
                items: [
                  (_ServiceType.solo,  l10n.solo),
                  (_ServiceType.multi, l10n.multi),
                ],
                primary: primary,
                onChanged: (v) => setState(() => _serviceType = v),
              ),
              const SizedBox(height: 12),
              _ToggleRow<_ApprovalMode>(
                label: l10n.approvalMode.toUpperCase(),
                value: _approvalMode,
                items: [
                  (_ApprovalMode.manual, l10n.manual),
                  (_ApprovalMode.auto,   l10n.autoApproval),
                ],
                primary: primary,
                onChanged: (v) => setState(() => _approvalMode = v),
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _waitingCtrl,
                label: l10n.waitingTime.toUpperCase(),
                hint: 'e.g. 15',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                  if (int.tryParse(v.trim()) == null) return l10n.enterNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _minAdvCtrl,
                label: l10n.minAdvance.toUpperCase(),
                hint: 'e.g. 60  (optional)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _maxAdvCtrl,
                label: l10n.maxAdvance.toUpperCase(),
                hint: 'e.g. 43200 = 30 days  (optional)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _cancelCtrl,
                label: l10n.freeCancellationDeadline.toUpperCase(),
                hint: 'e.g. 1440 = 24 h  (optional)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ]),

            const SizedBox(height: 16),

            // ── Availability Schedule ─────────────────────────────────────
            _SectionHeader(title: l10n.weeklySchedule, icon: Iconsax.calendar),
            _Card(children: [
              for (int i = 0; i < _days.length; i++) ...[
                if (i > 0) _CardDivider(),
                _DayRuleRow(
                  rule:    _days[i],
                  primary: primary,
                  onToggle: (v) => setState(() => _days[i].enabled = v),
                  onPickStart: () => _pickTime(_days[i], true),
                  onPickEnd:   () => _pickTime(_days[i], false),
                ),
              ],
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickBrand() async {
    final picked = await showModalBottomSheet<_BrandItem>(
      context: context,
      backgroundColor: context.dc.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet<_BrandItem>(
        title: context.l10n.selectBrand,
        items: _brands,
        labelOf: (b) => b.name,
        selectedId: _selectedBrandId,
        idOf: (b) => b.id,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedBrandId   = picked.id;
      _selectedBrandName = picked.name;
    });
  }

  Future<void> _pickCategory() async {
    final all = _categories.expand((c) => [c, ...c.children]).toList();
    final picked = await showModalBottomSheet<CategoryItem>(
      context: context,
      backgroundColor: context.dc.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet<CategoryItem>(
        title: context.l10n.selectCategory,
        items: all,
        labelOf: (c) => c.name,
        selectedId: _selectedCategoryId,
        idOf: (c) => c.id,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedCategoryId   = picked.id;
      _selectedCategoryName = picked.name;
    });
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tertiary = context.dc.textTertiary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tertiary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tertiary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for divider-separated rows (e.g. Weekly Schedule).
class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      decoration: BoxDecoration(
        color: dc.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.divider, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

/// Card with internal padding for form fields (no dividers).
class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dc.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 16,
        endIndent: 0,
        color: context.dc.divider,
      );
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: dc.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: dc.secondaryBackground,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 12 : 0,
            ),
            border: const OutlineInputBorder(
              borderRadius: _radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: _radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: _radius,
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: _radius,
              borderSide: BorderSide(color: AppPalette.error, width: 1.5),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: _radius,
              borderSide: BorderSide(color: AppPalette.error, width: 1.5),
            ),
            hintStyle: TextStyle(
              fontSize: 15,
              color: dc.textTertiary,
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              color: AppPalette.error,
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            color: dc.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    final dc = context.dc;
    final fillColor = dc.secondaryBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: dc.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: onTap != null ? fillColor : fillColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: onTap != null
                          ? dc.textPrimary
                          : dc.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: primary.withValues(alpha: 0.6),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.controller,
    required this.currency,
    required this.onCurrencyChange,
  });

  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onCurrencyChange;

  static const _radius     = BorderRadius.all(Radius.circular(12));
  static const _currencies = ['AZN', 'USD', 'EUR', 'TRY', 'GBP', 'RUB'];

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    final dc = context.dc;
    final fillColor = dc.secondaryBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.priceLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: dc.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: context.l10n.priceHint,
                  filled: true,
                  fillColor: fillColor,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: const OutlineInputBorder(
                      borderRadius: _radius,
                      borderSide: BorderSide.none),
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: _radius,
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: _radius,
                      borderSide: BorderSide(color: primary, width: 1.5)),
                  hintStyle: TextStyle(
                      fontSize: 15, color: dc.textTertiary),
                ),
                style: TextStyle(
                    fontSize: 15, color: dc.textPrimary),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currency,
                  items: _currencies
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onCurrencyChange(v);
                  },
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dc.textPrimary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


/// A full-width row with a small label above and a segmented control below.
/// No outer padding — place inside a [_FieldCard].
class _ToggleRow<T> extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.items,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> items;
  final Color primary;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: dc.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: dc.tertiaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: items.map(((T, String) item) {
              final selected = value == item.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : dc.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayRuleRow extends StatelessWidget {
  const _DayRuleRow({
    required this.rule,
    required this.primary,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final _DayRule rule;
  final Color primary;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              rule.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: rule.enabled ? dc.textPrimary : dc.textTertiary,
              ),
            ),
          ),
          Switch(
            value: rule.enabled,
            onChanged: onToggle,
            activeThumbColor: primary,
            activeTrackColor: primary.withValues(alpha: 0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (rule.enabled) ...[
            const SizedBox(width: 8),
            _TimeChip(
              time: rule.startTime,
              onTap: onPickStart,
              primary: primary,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(color: dc.textSecondary)),
            ),
            _TimeChip(
              time: rule.endTime,
              onTap: onPickEnd,
              primary: primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.onTap, required this.primary});
  final TimeOfDay time;
  final VoidCallback onTap;
  final Color primary;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _fmtTime(time),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      );
}

// ── Photo Picker ─────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.pickedImage,
    required this.existingPhotoUrl,
    required this.onTap,
  });

  final File?   pickedImage;
  final String? existingPhotoUrl;
  final VoidCallback onTap;

  bool get _hasPhoto => pickedImage != null || existingPhotoUrl != null;

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;

    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.divider, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: _hasPhoto ? _buildPreview(primary) : _buildEmpty(primary, dc),
      ),
    );
  }

  Widget _buildEmpty(Color primary, AppDynamicColors dc) {
    // BuildContext is not available here; strings are passed in via build
    // Use a Builder to access context for l10n
    return Builder(
      builder: (context) {
        final l10n = context.l10n;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.camera, color: primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.addServicePhoto,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tapToChoose,
                style: TextStyle(fontSize: 12, color: dc.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(Color primary) {
    final imageWidget = pickedImage != null
        ? Image.file(pickedImage!, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity)
        : Image.network(existingPhotoUrl!, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity);

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Gradient overlay at bottom
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        // "Change" label
        Positioned(
          left: 12, bottom: 10,
          child: Builder(
            builder: (context) => Row(
              children: [
                const Icon(Iconsax.camera, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  context.l10n.changePhoto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Generic Picker Sheet ─────────────────────────────────────────────────────

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.idOf,
    this.selectedId,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T) idOf;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.dc.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final item   = items[i];
                final isSelected = idOf(item) == selectedId;
                return ListTile(
                  title: Text(
                    labelOf(item),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppPalette.success)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      );
}
