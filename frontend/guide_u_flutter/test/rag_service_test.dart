import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guide_u_flutter/services/rag_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // FIX 1: Provide a fake SharedPreferences so Supabase doesn't crash
    SharedPreferences.setMockInitialValues({});

    // FIX 2: Disable Flutter's default block on internet requests during tests
    HttpOverrides.global = null;

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );
  });

  test('GuideU Service should return a valid handbook answer', () async {
    final service = GuideURagService();

    final query = "What are the penalties for vandalism?";

    print("Sending query: $query");
    final response = await service.askQuestion(query);

    print("Received response: $response");

    expect(response.isNotEmpty, true);
    expect(response.contains("An error occurred"), false);
  });
}
