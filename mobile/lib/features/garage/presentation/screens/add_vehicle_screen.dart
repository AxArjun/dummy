// FuelIQ — Add Vehicle Screen
// Vehicle registration form with validation

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../providers/vehicle_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/models.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();
  final _tankCapacityController = TextEditingController();
  final _odometerController = TextEditingController();

  FuelType _selectedFuelType = FuelType.petrol;
  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isPrimary = false;
  bool _isSubmitting = false;

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _tankCapacityController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final vehicle = Vehicle(
      id: const Uuid().v4(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      fuelType: _selectedFuelType,
      vehicleType: _selectedVehicleType,
      licensePlate: _licensePlateController.text.trim().isEmpty
          ? null
          : _licensePlateController.text.trim().toUpperCase(),
      color: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
      tankCapacityLiters: _tankCapacityController.text.trim().isEmpty
          ? null
          : double.tryParse(_tankCapacityController.text.trim()),
      initialOdometer:
          double.tryParse(_odometerController.text.trim()) ?? 0,
      currentOdometer:
          double.tryParse(_odometerController.text.trim()) ?? 0,
      isPrimary: _isPrimary,
      isArchived: false,
      createdAt: DateTime.now(),
    );

    await ref.read(vehicleListProvider.notifier).addVehicle(vehicle);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${vehicle.make} ${vehicle.model} added to your garage'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go(AppRoutes.home);
    }
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
          'Add Vehicle',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _isSubmitting ? _textSub : _gold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vehicle Type ───────────────────────────────────────
                _buildSectionHeader('Vehicle Type'),
                const SizedBox(height: 12),
                _buildVehicleTypePicker(),

                const SizedBox(height: 24),

                // ── Basic Info ─────────────────────────────────────────
                _buildSectionHeader('Basic Information'),
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _makeController,
                              label: 'Brand / Make',
                              hint: 'e.g. BMW',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Brand is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _modelController,
                              label: 'Model',
                              hint: 'e.g. 3 Series',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Model is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _yearController,
                              label: 'Year',
                              hint: '2023',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Year required';
                                }
                                final year = int.tryParse(v.trim());
                                if (year == null ||
                                    year < 1900 ||
                                    year > DateTime.now().year + 1) {
                                  return 'Invalid year';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _colorController,
                              label: 'Color',
                              hint: 'Alpine White',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _licensePlateController,
                        label: 'Registration Number',
                        hint: 'MH 01 AB 1234',
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                const SizedBox(height: 24),

                // ── Fuel Type ──────────────────────────────────────────
                _buildSectionHeader('Fuel Type'),
                const SizedBox(height: 12),
                _buildFuelTypePicker(),

                const SizedBox(height: 24),

                // ── Technical Specs ────────────────────────────────────
                _buildSectionHeader('Technical Details'),
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _tankCapacityController,
                              label: 'Tank Capacity (L)',
                              hint: '60',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final d = double.tryParse(v);
                                  if (d == null || d <= 0) {
                                    return 'Invalid capacity';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _odometerController,
                              label: 'Current Odometer (km)',
                              hint: '0',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final d = double.tryParse(v);
                                  if (d == null || d < 0) {
                                    return 'Invalid reading';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Primary toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isPrimary = !_isPrimary),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _isPrimary,
                                onChanged: (v) =>
                                    setState(() => _isPrimary = v ?? false),
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
                                    'Set as primary vehicle',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'This will be your default vehicle',
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
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                const SizedBox(height: 32),

                // ── Save button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xFF0B0B0B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      disabledBackgroundColor: _gold.withOpacity(0.4),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0B0B0B)),
                          )
                        : const Text(
                            'Add to Garage',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 60),
              ],
            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
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
          textCapitalization: textCapitalization,
          validator: validator,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildVehicleTypePicker() {
    final types = [
      (VehicleType.car, Icons.directions_car_rounded, 'Car'),
      (VehicleType.motorcycle, Icons.two_wheeler_rounded, 'Motorcycle'),
      (VehicleType.scooter, Icons.electric_scooter_rounded, 'Scooter'),
      (VehicleType.truck, Icons.local_shipping_rounded, 'Truck'),
      (VehicleType.van, Icons.airport_shuttle_rounded, 'Van'),
      (VehicleType.other, Icons.directions_rounded, 'Other'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = _selectedVehicleType == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedVehicleType = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _gold.withOpacity(0.12) : _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? _gold : _border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2,
                    size: 18,
                    color: isSelected ? _gold : _textSub),
                const SizedBox(width: 8),
                Text(
                  t.$3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? _gold : _textSub,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFuelTypePicker() {
    final types = [
      (FuelType.petrol, 'Petrol'),
      (FuelType.diesel, 'Diesel'),
      (FuelType.cng, 'CNG'),
      (FuelType.electric, 'Electric'),
      (FuelType.hybrid, 'Hybrid'),
      (FuelType.lpg, 'LPG'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = _selectedFuelType == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedFuelType = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _gold.withOpacity(0.12) : _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? _gold : _border, width: 1.5),
            ),
            child: Text(
              t.$2,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? _gold : _textSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
