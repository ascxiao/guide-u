import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/lost_found_report_view_model.dart';
import 'lost_found_report_detail_page.dart';

class HandbookLostAndFoundHistoryPage extends StatelessWidget {
  const HandbookLostAndFoundHistoryPage({Key? key}) : super(key: key);

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
        return 'Open';
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
    return Consumer<LostFoundReportViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('My Report History'),
            backgroundColor: Colors.white,
            foregroundColor: _mainGreen,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: _mainGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _mainGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: viewModel.loading
                          ? _mainGreen.withValues(alpha: 0.35)
                          : _mainGreen,
                      size: 18,
                    ),
                    onPressed: viewModel.loading
                        ? null
                        : viewModel.refreshHistory,
                  ),
                ),
              ),
            ],
          ),
          body: viewModel.loading
              ? const Center(
                  child: CircularProgressIndicator(color: _mainGreen),
                )
              : viewModel.history.isEmpty
              ? const Center(
                  child: Text('No lost and found reports submitted yet.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.history.length,
                  itemBuilder: (context, index) {
                    final report = viewModel.history[index];
                    final color = _statusColor(report.status);

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LostFoundReportDetailPage(report: report),
                        ),
                      ),
                      child: Container(
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
                                    report.itemName.isEmpty
                                        ? 'Unnamed Item'
                                        : report.itemName,
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
                              'Type: ${report.reportType.isEmpty ? '-' : report.reportType}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
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
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
