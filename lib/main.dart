import 'package:flutter/material.dart';
import 'package:ace/shared/theme/app_theme.dart';
import 'package:ace/routes/router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TennisTrackerUI());
}

class TennisTrackerUI extends StatefulWidget {
  const TennisTrackerUI({super.key});

  @override
  State<TennisTrackerUI> createState() => _TennisTrackerUIState();
}

class _TennisTrackerUIState extends State<TennisTrackerUI> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Ace Tennis",
      theme: buildAppTheme(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('de', 'DE')],
    );
  }
}
