import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/providers.dart';
import '../../domain/entities/asset_entity.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _category = 'Equipment';
  String _status = 'Good';
  double _latitude = 0.0;
  double _longitude = 0.0;

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newAsset = AssetEntity(
      id: const Uuid().v4(),
      assetName: _name,
      category: _category,
      status: _status,
      latitude: _latitude,
      longitude: _longitude,
      syncStatus: SyncStatus.pendingSync,
      timestamp: DateTime.now(),
    );

    print(newAsset.id);
    ref.read(assetListProvider.notifier).addAsset(newAsset);
    Navigator.of(context).pop();
  }

  // ── Color palette ──────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1A1D27);
  static const _surfaceHigh = Color(0xFF22263A);
  static const _accent = Color(0xFF4F8EF7);
  static const _accentSoft = Color(0x264F8EF7);
  static const _textPrimary = Color(0xFFECEFF4);
  static const _textSecondary = Color(0xFF7B849A);
  static const _border = Color(0xFF2E3347);
  static const _errorColor = Color(0xFFFF5C72);

  // ── Reusable section label ─────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 2,
            color: _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ── Styled TextFormField ───────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        TextFormField(
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(color: _textSecondary, size: 18),
                    child: prefixIcon,
                  )
                : null,
            filled: true,
            fillColor: _surfaceHigh,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorColor, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: _errorColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  // ── Styled DropdownButtonFormField ─────────────────────────────────────────
  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: _surfaceHigh,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.unfold_more_rounded,
              color: _textSecondary, size: 20),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(color: _textSecondary, size: 18),
                    child: prefixIcon,
                  )
                : null,
            filled: true,
            fillColor: _surfaceHigh,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i,
                    child: Text(i.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Status chip indicator ──────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Good':
        return const Color(0xFF34D399);
      case 'Needs Repair':
        return const Color(0xFFFBBF24);
      case 'Broken':
        return _errorColor;
      default:
        return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          error: _errorColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textSecondary, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Record New Asset',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            color: _accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Asset Entry',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Will be queued for sync on submission',
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFFBBF24).withOpacity(0.4)),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Section: Asset Details ───────────────────────────────────
                _buildSectionHeader('Asset Details', Icons.label_outline_rounded),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Asset Name',
                  hint: 'e.g. Field Generator Unit A3',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Asset name cannot be empty';
                    return null;
                  },
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 16),

                _buildDropdown<String>(
                  label: 'Category',
                  value: _category,
                  prefixIcon: const Icon(Icons.category_outlined),
                  items: ['Equipment', 'Sample', 'Infrastructure'],
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 16),

                // Status with live color indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _sectionLabel('Condition Status'),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(_status),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _statusColor(_status).withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _status,
                          style: TextStyle(
                            color: _statusColor(_status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: _status,
                      dropdownColor: _surfaceHigh,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: const Icon(Icons.unfold_more_rounded,
                          color: _textSecondary, size: 20),
                      decoration: InputDecoration(
                        prefixIcon: const IconTheme(
                          data: IconThemeData(color: _textSecondary, size: 18),
                          child: Icon(Icons.health_and_safety_outlined),
                        ),
                        filled: true,
                        fillColor: _surfaceHigh,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _border, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                      items: ['Good', 'Needs Repair', 'Broken']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _statusColor(s),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(s),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Section: GPS Coordinates ─────────────────────────────────
                _buildSectionHeader(
                    'GPS Coordinates', Icons.location_on_outlined),
                const SizedBox(height: 4),
                const Text(
                  'Decimal degrees format  •  WGS 84',
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Latitude',
                        hint: '−90 to 90',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: const Icon(Icons.swap_vert_rounded),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Please enter a latitude';
                          final lat = double.tryParse(val);
                          if (lat == null) return 'Must be a valid decimal number';
                          if (lat < -90.0 || lat > 90.0)
                            return 'Latitude must fall between -90 and 90';
                          return null;
                        },
                        onSaved: (val) => _latitude = double.parse(val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Longitude',
                        hint: '−180 to 180',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: const Icon(Icons.swap_horiz_rounded),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Please enter a longitude';
                          final lng = double.tryParse(val);
                          if (lng == null) return 'Must be a valid decimal number';
                          if (lng < -180.0 || lng > 180.0)
                            return 'Longitude must fall between -180 and 180';
                          return null;
                        },
                        onSaved: (val) => _longitude = double.parse(val!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Submit button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload_outlined, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Submit Asset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtle helper note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: _textSecondary),
                      SizedBox(width: 5),
                      Text(
                        'Asset will sync automatically when online',
                        style:
                            TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    );
  }
}