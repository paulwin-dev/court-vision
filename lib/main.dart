import 'package:flutter/material.dart';
import 'package:ace/shared/theme/app_theme.dart';
import 'package:ace/routes/router.dart';

void main() {
	runApp(const TennisTrackerUI());
}

class TennisTrackerUI extends StatelessWidget {
	const TennisTrackerUI({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Ace Tennis",
      
      theme: buildAppTheme(), 
      
      routerConfig: router, 
    );
	}
}