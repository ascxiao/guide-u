import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'handbook_bottom_nav_bar.dart';
import 'handbook_lost_and_found_history_page.dart';
import '../widgets/internet_required_notice.dart';
import '../view_models/lost_found_report_view_model.dart';

class HandbookLostAndFoundPage extends StatefulWidget {
  const HandbookLostAndFoundPage({Key? key}) : super(key: key);

  @override
  State<HandbookLostAndFoundPage> createState() =>
      _HandbookLostAndFoundPageState();
}

class _HandbookLostAndFoundPageState extends State<HandbookLostAndFoundPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();

  static const _mainGreen = Color(0xFF1F7A5A);
  static const _accentGreen = Color(0xFF4FBF8F);
  static const _softGreen = Color(0xFFE6F4EF);

  String _reportType = 'Lost';

  String _studentIdPlaceholderFromEmail(String email, String fallback) {
    final localPart = email.split('@').first;
    final digits = localPart.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return fallback;
    return digits.length > 7 ? digits.substring(0, 7) : digits;
  }

  void _syncProfileFields(LostFoundReportViewModel viewModel) {
    if (!viewModel.useProfileInfo) return;

    if (_emailController.text != viewModel.defaultEmail) {
      _emailController.text = viewModel.defaultEmail;
    }
    if (_studentIdController.text.isNotEmpty) {
      _studentIdController.clear();
    }
  }

  void _handleProfileInfoToggle(
    LostFoundReportViewModel viewModel,
    bool checked,
  ) {
    viewModel.setUseProfileInfo(checked);

    if (checked) {
      _emailController.text = viewModel.defaultEmail;
      _studentIdController.clear();
      return;
    }

    _emailController.clear();
    _studentIdController.clear();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _studentIdController.dispose();
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit(LostFoundReportViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await viewModel.submit(
      itemName: _itemNameController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      reportType: _reportType,
      reporterEmail: _emailController.text,
      reporterStudentId: _studentIdController.text,
    );

    if (!mounted) return;

    if (ok) {
      _itemNameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lost and found report submitted.')),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(viewModel.error!)));
    }
  }

  void _openHistory(LostFoundReportViewModel viewModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: const HandbookLostAndFoundHistoryPage(),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required.';
    const emailPattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateStudentId(String? value) {
    final studentId = (value ?? '').trim();
    if (studentId.isEmpty) return 'Student ID is required.';
    if (!RegExp(r'^\d{1,7}$').hasMatch(studentId)) {
      return 'Student ID must be up to 7 digits.';
    }
    return null;
  }

  InputDecoration _modernInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mainGreen),
      prefixIcon: Icon(icon, color: _mainGreen),
      filled: true,
      fillColor: const Color(0xFFF8FCFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7EDE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _mainGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _softGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _mainGreen),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _mainGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LostFoundReportViewModel()..initialize(),
      child: Consumer<LostFoundReportViewModel>(
        builder: (context, viewModel, _) {
          _syncProfileFields(viewModel);

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text(
                'Lost and Found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: _mainGreen,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.loading
                      ? null
                      : viewModel.refreshHistory,
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  const InternetRequiredNotice(featureName: 'Lost and found'),

                  GestureDetector(
                    onTap: viewModel.loading
                        ? null
                        : () => _openHistory(viewModel),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCEFE7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _softGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: _mainGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Report History',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _mainGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  viewModel.loading
                                      ? 'Loading reports...'
                                      : '${viewModel.history.length} report(s) submitted',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _mainGreen,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_accentGreen, _mainGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report a Lost or Found Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Provide details below to help us locate or return lost items.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  _buildInputSection(
                    title: 'Your Information',
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _modernInputDecoration(
                          label: 'Full Name',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        readOnly: viewModel.useProfileInfo,
                        validator: _validateEmail,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: _modernInputDecoration(
                          label: 'Email Address',
                          icon: Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: _modernInputDecoration(
                          label: 'Contact Number',
                          icon: Icons.call_outlined,
                        ).copyWith(prefixText: '+63 '),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _studentIdController,
                        readOnly: viewModel.useProfileInfo,
                        keyboardType: TextInputType.number,
                        validator: (value) => viewModel.useProfileInfo
                            ? null
                            : _validateStudentId(value),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        decoration:
                            _modernInputDecoration(
                              label: 'Student ID (for updates)',
                              icon: Icons.credit_card_outlined,
                            ).copyWith(
                              floatingLabelBehavior: viewModel.useProfileInfo
                                  ? FloatingLabelBehavior.always
                                  : FloatingLabelBehavior.auto,
                              hintText: viewModel.useProfileInfo
                                  ? _studentIdPlaceholderFromEmail(
                                      viewModel.defaultEmail,
                                      viewModel.defaultStudentId,
                                    )
                                  : null,
                              hintStyle: viewModel.useProfileInfo
                                  ? const TextStyle(color: Colors.black54)
                                  : null,
                              helperText: viewModel.useProfileInfo
                                  ? 'Auto-derived from profile email.'
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: _softGreen.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD7EDE3)),
                        ),
                        child: CheckboxListTile(
                          value: viewModel.useProfileInfo,
                          onChanged: (checked) => _handleProfileInfoToggle(
                            viewModel,
                            checked ?? false,
                          ),
                          activeColor: _mainGreen,
                          checkColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: const Text('Use my profile email/student ID'),
                          subtitle: const Text(
                            'Optional auto-fill for reporter information.',
                          ),
                        ),
                      ),
                    ],
                  ),

                  _buildInputSection(
                    title: 'Item Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      TextFormField(
                        controller: _itemNameController,
                        decoration: _modernInputDecoration(
                          label: 'Item Name',
                          icon: Icons.label_outline,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Item name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _modernInputDecoration(
                          label: 'Description',
                          icon: Icons.notes_outlined,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: _modernInputDecoration(
                          label: 'Location Found / Lost',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: _modernInputDecoration(
                          label: 'Report Type',
                          icon: Icons.swap_horiz,
                        ),
                        value: _reportType,
                        items: const [
                          DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                          DropdownMenuItem(
                            value: 'Found',
                            child: Text('Found'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _reportType = value ?? 'Lost';
                          });
                        },
                      ),
                    ],
                  ),

                  _buildInputSection(
                    title: 'Upload a Photo (optional)',
                    icon: Icons.photo_library_outlined,
                    children: [
                      OutlinedButton.icon(
                        onPressed: viewModel.submitting
                            ? null
                            : viewModel.pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Select photos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _mainGreen,
                          side: const BorderSide(color: _mainGreen),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (viewModel.images.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(viewModel.images.length, (
                            index,
                          ) {
                            final image = viewModel.images[index];
                            return Chip(
                              backgroundColor: _softGreen,
                              side: const BorderSide(color: Color(0xFFD7EDE3)),
                              label: Text(
                                image.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              deleteIconColor: _mainGreen,
                              onDeleted: () => viewModel.removeImageAt(index),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mainGreen,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: viewModel.submitting
                        ? null
                        : () => _submit(viewModel),
                    child: Text(
                      viewModel.submitting ? 'Submitting...' : 'Submit Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  if (viewModel.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      viewModel.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 1),
          );
        },
      ),
    );
  }
}
