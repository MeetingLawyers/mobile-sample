import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'meeting_pros/meeting_pros.dart';

// Demo credentials come from the repo-root .env: flutter run --dart-define-from-file=../../.env
const lawyersApiKey = String.fromEnvironment('ML_API_KEY');
const doctorsApiKey = String.fromEnvironment('MD_API_KEY');
const userId = String.fromEnvironment('ML_USER_ID');
const isProduction = String.fromEnvironment('ML_ENVIRONMENT') == 'PROD';
const brandColor = Color(0xFF2E7D6B);

void main() => runApp(const SampleApp());

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MeetingPros Sample',
        theme: ThemeData(colorSchemeSeed: brandColor),
        home: const HomePage(),
      );
}

enum Status { missingCredentials, configuring, configured, authenticated }

/// Home screen: sign in, open the lawyers, doctors or vets list, a lawyer chat or a doctors feature, log out.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _hash = TextEditingController();
  var _status = Status.configuring;
  var _features = <DoctorsFeature>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  Future<void> _configure() async {
    if (lawyersApiKey.isEmpty || doctorsApiKey.isEmpty || userId.isEmpty) {
      setState(() => _status = Status.missingCredentials);
      return;
    }
    await _run(() async {
      await MeetingPros.configure(lawyersApiKey: lawyersApiKey, doctorsApiKey: doctorsApiKey, isProduction: isProduction);
      await MeetingPros.configureTheme(brandColor.toARGB32());
      if (await MeetingPros.isAuthenticated()) {
        await _signedIn();
      } else {
        setState(() => _status = Status.configured);
      }
    });
  }

  Future<void> _signedIn() async {
    final features = await MeetingPros.availableFeatures();
    setState(() {
      _features = features;
      _status = Status.authenticated;
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
      appBar: AppBar(title: const Text('MeetingPros Sample')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: ${_status.name} (${isProduction ? 'PROD' : 'DEV'})',
              style: Theme.of(context).textTheme.titleMedium),
          if (_status == Status.missingCredentials)
            const Text('Run with --dart-define-from-file=../../.env and fill in ML_API_KEY, MD_API_KEY and ML_USER_ID.'),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          button('Sign in', () async {
            await MeetingPros.authenticate(userId);
            await _signedIn();
          }, enabled: _status == Status.configured),
          for (final type in ProfessionalType.values)
            button('Open ${type.name} list', () => MeetingPros.openProfessionalList(type), enabled: signedIn),
          TextField(controller: _hash, decoration: const InputDecoration(labelText: "Lawyer's professional hash")),
          button('Open lawyer chat', () => MeetingPros.openLawyerChat(_hash.text.trim()), enabled: signedIn),
          for (final feature in DoctorsFeature.values)
            button('Open ${feature.name}', () => MeetingPros.openFeature(feature),
                enabled: signedIn && _features.contains(feature)),
          button('Log out', () async {
            await MeetingPros.logout();
            setState(() {
              _features = {};
              _status = Status.configured;
            });
          }, enabled: signedIn),
        ],
      ),
    );
  }
}
