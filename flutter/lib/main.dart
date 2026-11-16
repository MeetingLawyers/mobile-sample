import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'meeting_lawyers/meeting_lawyers.dart';

// Demo credentials come from the repo-root .env: flutter run --dart-define-from-file=../.env
const apiKey = String.fromEnvironment('ML_API_KEY');
const userId = String.fromEnvironment('ML_USER_ID');
const isProduction = String.fromEnvironment('ML_ENVIRONMENT') == 'PROD';
const brandColor = Color(0xFF1E5AA8);
const brandHex = '#1E5AA8';

void main() => runApp(const SampleApp());

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MeetingLawyers Sample',
        theme: ThemeData(colorSchemeSeed: brandColor),
        home: const HomePage(),
      );
}

enum Status { missingCredentials, configuring, configured, authenticated }

/// Home screen: sign in, open the professional list or a chat, log out.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _hash = TextEditingController();
  var _status = Status.configuring;
  String? _error;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  Future<void> _configure() async {
    if (apiKey.isEmpty || userId.isEmpty) {
      setState(() => _status = Status.missingCredentials);
      return;
    }
    await _run(() async {
      await MeetingLawyers.configure(apiKey: apiKey, isProduction: isProduction);
      const color = brandHex;
      await MeetingLawyers.configureTheme(
        primaryColor: color,
        secondaryColor: color,
        navigationBarColor: color,
        outgoingMessageColor: color,
      );
      final signedIn = await MeetingLawyers.isAuthenticated();
      setState(() => _status = signedIn ? Status.authenticated : Status.configured);
    });
  }

  /// Runs a plugin call and shows its error, if any.
  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _error = null);
    try {
      await operation();
    } on PlatformException catch (e) {
      setState(() => _error = e.message ?? e.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _status == Status.authenticated;
    Widget button(String title, Future<void> Function() action, {bool enabled = true}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton(onPressed: enabled ? () => _run(action) : null, child: Text(title)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('MeetingLawyers Sample')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: ${_status.name} (${isProduction ? 'PROD' : 'DEV'})',
              style: Theme.of(context).textTheme.titleMedium),
          if (_status == Status.missingCredentials)
            const Text('Run with --dart-define-from-file=../.env and fill in ML_API_KEY and ML_USER_ID.'),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          button('Sign in', () async {
            await MeetingLawyers.authenticate(userId);
            setState(() => _status = Status.authenticated);
          }, enabled: _status == Status.configured),
          button('Open professional list', MeetingLawyers.openProfessionalList, enabled: signedIn),
          TextField(controller: _hash, decoration: const InputDecoration(labelText: 'Professional hash')),
          button('Open chat', () => MeetingLawyers.openChat(_hash.text.trim()), enabled: signedIn),
          button('Log out', () async {
            await MeetingLawyers.logout();
            setState(() => _status = Status.configured);
          }, enabled: signedIn),
        ],
      ),
    );
  }
}
