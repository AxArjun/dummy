// FuelIQ — Add Fuel Screen
// Premium fuel log entry form

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../providers/fuel_provider.dart';
import '../../../../shared/models/models.dart';

class AddFuelScreen extends ConsumerStatefulWidget {
  const AddFuelScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends ConsumerState<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _volumeController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isFullTank = true;
  bool _isSubmitting = false;
  DateTime _filledAt = DateTime.now();

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);

  @override
  void dispose() {
    _odometerController.dispose();
    _volumeController.dispose();
    _totalCostController.dispose();
    _pricePerLiterController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _autoCalculatePrice() {
    final volume = double.tryParse(_volumeController.text);
    final total = double.tryParse(_totalCostController.text);
    if (volume != null && total != null && volume > 0) {
      final ppl = total / volume;
      _pricePerLiterController.text = ppl.toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _gold,
              onPrimary: Color(0xFF0B0B0B),
              surface: Color(0xFF1A1A1A),
              onSurface: Color(0xFFF5F5F5),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _filledAt = picked);
  }

  void _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final volume = double.parse(_volumeController.text.trim());
    final total = double.parse(_totalCostController.text.trim());
    final ppl = double.tryParse(_pricePerLiterController.text.trim()) ??
        total / volume;
    final odometer = double.parse(_odometerController.text.trim());

    final log = FuelLog(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      odometerReading: odometer,
      volumeLiters: volume,
      pricePerLiter: ppl,
      totalCost: total,
      isFullTank: _isFullTank,
      stationName: _stationController.text.trim().isEmpty
          ? null
          : _stationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      loggedVia: 'manual',
      filledAt: _filledAt,
      createdAt: DateTime.now(),
    );

    await ref
        .read(fuelNotifierProvider(widget.vehicleId).notifier)
        .addLog(log);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Fuel log saved — ${volume.toStringAsFixed(1)} L'),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    }
  }

  void _handleScanReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OCR Receipt Scanner coming soon'),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textPrimary, size: 16),
          ),
        ),
        title: const Text(
          'Add Fuel Entry',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        actions: [
          // Scan receipt button
          GestureDetector(
            onTap: _handleScanReceipt,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.document_scanner_outlined,
                      color: _gold, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Scan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date selector ────────────────────────────────────────
              _buildDateSelector(),
              const SizedBox(height: 20),

              // ── Core readings ────────────────────────────────────────
              _buildSectionHeader('Readings'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _odometerController,
                      label: 'Odometer Reading (km)',
                      hint: '24850',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.speed_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Odometer reading required';
                        }
                        final d = double.tryParse(v.trim());
                        if (d == null || d < 0) return 'Invalid reading';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _volumeController,
                            label: 'Fuel (Litres)',
                            hint: '45.5',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.local_gas_station_rounded,
                            onChanged: (_) => _autoCalculatePrice(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Volume required';
                              }
                              final d = double.tryParse(v.trim());
                              if (d == null || d <= 0) {
                                return 'Invalid volume';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _totalCostController,
                            label: 'Total Cost (₹)',
                            hint: '4845.75',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee_rounded,
                            onChanged: (_) => _autoCalculatePrice(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Cost required';
                              }
                              final d = double.tryParse(v.trim());
                              if (d == null || d <= 0) {
                                return 'Invalid cost';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _pricePerLiterController,
                      label: 'Price per Litre (₹) — auto-calculated',
                      hint: '106.50',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money_rounded,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

              const SizedBox(height: 20),

              // ── Station ──────────────────────────────────────────────
              _buildSectionHeader('Station Details'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: _buildTextField(
                  controller: _stationController,
                  label: 'Station Name (optional)',
                  hint: 'HP Petrol Pump, Bandra',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 20),

              // ── Options ──────────────────────────────────────────────
              _buildSectionHeader('Options'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isFullTank = !_isFullTank),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isFullTank,
                              onChanged: (v) => setState(
                                  () => _isFullTank = v ?? true),
                              activeColor: _gold,
                              side: const BorderSide(
                                  color: _border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full tank fill-up',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Required for accurate efficiency calculation',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: _textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Notes (optional)',
                      hint: 'Any additional notes...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSave,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0B0B0B)),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Saving...' : 'Save Fuel Entry',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: const Color(0xFF0B0B0B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: _gold.withOpacity(0.4),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textSub,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: _gold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fill Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: _textSub,
                    ),
                  ),
                  Text(
                    '${_filledAt.day}/${_filledAt.month}/${_filledAt.year}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded,
                color: _textSub, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSub,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: _textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: _textSub, fontSize: 13),
            fillColor: const Color(0xFF0F0F0F),
            filled: true,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _textSub, size: 18)
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFF44336)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFFF44336), width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFFF44336),
            ),
          ),
        ),
      ],
    );
  }
}
