import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'handbook_bottom_nav_bar.dart';
import '../widgets/internet_required_notice.dart';
import '../widgets/handbook_chatbot_fab.dart';
import '../view_models/incident_report_view_model.dart';

class HandbookIncidentPage extends StatefulWidget {
  const HandbookIncidentPage({Key? key}) : super(key: key);

  @override
  State<HandbookIncidentPage> createState() => _HandbookIncidentPageState();
}

class _HandbookIncidentPageState extends State<HandbookIncidentPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _incidentType = 'Safety';
  String _severityLevel = 'Minor';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _studentIdController.dispose();
    _dateTimeController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(IncidentReportViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await viewModel.submit(
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      reporterEmail: _emailController.text,
      reporterStudentId: _studentIdController.text,
    );

    if (!mounted) return;

    if (ok) {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _dateTimeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident report submitted.')),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.error!)),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_review':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'under_review':
        return const Color(0xFF1565C0);
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'closed':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF9E7700);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$mm/$dd/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncidentReportViewModel()..initialize(),
      child: Consumer<IncidentReportViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.useProfileInfo) {
            _emailController.text = viewModel.defaultEmail;
            _studentIdController.text = viewModel.defaultStudentId;
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F4F4),
            appBar: AppBar(
              title: const Text(
                'Incident Reporting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006633),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.loading ? null : viewModel.refreshHistory,
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const InternetRequiredNotice(featureName: 'Incident reporting'),

                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A86B), Color(0xFF006633)],
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
                          'Report an Incident',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fill out the details below so that the incident can be properly addressed.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF006633),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            enabled: !viewModel.useProfileInfo,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _studentIdController,
                            enabled: !viewModel.useProfileInfo,
                            decoration: const InputDecoration(
                              labelText: 'Student ID (for updates)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: viewModel.useProfileInfo,
                            onChanged: (checked) =>
                                viewModel.setUseProfileInfo(checked ?? false),
                            activeColor: const Color(0xFF006633),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use my profile email/student ID'),
                            subtitle: const Text(
                              'Optional auto-fill for reporter information.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Incident Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF006633),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Incident Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Title is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dateTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Date & Time',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                color: Color(0xFF006633),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Type of Incident',
                              border: OutlineInputBorder(),
                            ),
                            value: _incidentType,
                            items: const [
                              DropdownMenuItem(value: 'Safety', child: Text('Safety')),
                              DropdownMenuItem(
                                value: 'Security',
                                child: Text('Security'),
                              ),
                              DropdownMenuItem(
                                value: 'Harassment',
                                child: Text('Harassment'),
                              ),
                              DropdownMenuItem(
                                value: 'Property Damage',
                                child: Text('Property Damage'),
                              ),
                              DropdownMenuItem(
                                value: 'IT/Network',
                                child: Text('IT/Network'),
                              ),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _incidentType = value ?? 'Safety';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Severity Level',
                              border: OutlineInputBorder(),
                            ),
                            value: _severityLevel,
                            items: const [
                              DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                              DropdownMenuItem(
                                value: 'Moderate',
                                child: Text('Moderate'),
                              ),
                              DropdownMenuItem(value: 'Major', child: Text('Major')),
                              DropdownMenuItem(
                                value: 'Critical',
                                child: Text('Critical'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _severityLevel = value ?? 'Minor';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: viewModel.submitting ? null : viewModel.pickImages,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add photos'),
                          ),
                          if (viewModel.images.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(viewModel.images.length, (index) {
                                final image = viewModel.images[index];
                                return Chip(
                                  label: Text(
                                    image.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () => viewModel.removeImageAt(index),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006633),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: viewModel.submitting ? null : () => _submit(viewModel),
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

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Incident Reports',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF006633),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (viewModel.loading)
                            const Center(child: CircularProgressIndicator())
                          else if (viewModel.history.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No incident reports submitted yet.'),
                            )
                          else
                            ...viewModel.history.map((report) {
                              final color = _statusColor(report.status);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report.title.isEmpty
                                                ? 'Untitled Incident'
                                                : report.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: color.withOpacity(0.12),
                                          ),
                                          child: Text(
                                            _statusLabel(report.status),
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Submitted: ${_formatDate(report.createdAt)}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (report.location.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Location: ${report.location}'),
                                    ],
                                    if ((report.adminNote ?? '').trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Admin Note',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(report.adminNote!.trim()),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 3),
          );
        },
      ),
      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 3),
      floatingActionButton: const HandbookChatbotFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
