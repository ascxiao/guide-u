import 'package:flutter/material.dart';
import 'handbook_bottom_nav_bar.dart';
import '../widgets/internet_required_notice.dart';

class HandbookIncidentPage extends StatelessWidget {
  const HandbookIncidentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InternetRequiredNotice(featureName: 'Incident reporting'),

          // Instructions / Header
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

          // Reporter Info
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
                children: const [
                  Text(
                    'Your Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF006633),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Incident Details
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
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Date & Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Color(0xFF006633),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
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
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Severity Level',
                      border: OutlineInputBorder(),
                    ),
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
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006633),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'Submit Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 3),
    );
  }
}
