import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/incident_report_view_model.dart';

class HandbookIncidentHistoryPage extends StatelessWidget {
  const HandbookIncidentHistoryPage({Key? key}) : super(key: key);

  static const _mainGreen = Color(0xFF1F7A5A);

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
    return Consumer<IncidentReportViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('My Report History'),
            backgroundColor: Colors.white,
            foregroundColor: _mainGreen,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.loading ? null : viewModel.refreshHistory,
              ),
            ],
          ),
          body: viewModel.loading
              ? const Center(
                  child: CircularProgressIndicator(color: _mainGreen),
                )
              : viewModel.history.isEmpty
              ? const Center(child: Text('No incident reports submitted yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.history.length,
                  itemBuilder: (context, index) {
                    final report = viewModel.history[index];
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
                  },
                ),
        );
      },
    );
  }
}
