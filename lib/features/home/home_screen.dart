import 'package:ace/features/matches/match_classes.dart';
import 'package:ace/routes/router.dart';
import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';

final List<RecentMatch> recentMatches = [
  RecentMatch(
    opponentName: 'Alex',
    score: '6-4 7-5',
    date: 'May 5, 2026',
    isWin: true,
  ),
  RecentMatch(
    opponentName: 'Bobby Dylannoise',
    score: '1-6 1-6',
    date: 'May 5, 2026',
    isWin: false,
  ),
];

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenPage> {
  final ExpansibleController _matchPresetExpansionController =
      ExpansibleController();
  final TextEditingController _opponentController = TextEditingController();
  String selectedMatchPreset = "Default";

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.zero,
          child: Column(
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // forces full width
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'icons/BottomTextNoBackground.png',
                      width: 160,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 400,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.outline, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 30,
                          left: 8,
                          right: 8,
                          bottom: 8,
                        ),
                        child: ListView.builder(
                          itemCount: recentMatches.length,
                          itemBuilder: (context, index) {
                            final match = recentMatches[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        match.opponentName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        match.date,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: colors.surfaceBright,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        match.score,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: match.isWin
                                              ? colors.primary.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          match.isWin ? 'WIN' : 'LOSS',
                                          style: GoogleFonts.outfit(
                                            color: match.isWin
                                                ? colors.primary
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'RECENT MATCHES',
                        style: GoogleFonts.outfit(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 350,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.outline, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  child: Text(
                    'PROFILE & SETTINGS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Spacer(),
              SizedBox(
                width: 350,
                child: OutlinedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: colors.background,
                      isScrollControlled: true,
                      sheetAnimationStyle: AnimationStyle(
                        curve: Curves.bounceIn, // This provides the overshoot
                        duration: const Duration(milliseconds: 200),
                      ),
                      builder: (context) {
                        return buildNewMatchModal(context);
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.outline, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    'NEW MATCH',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  StatefulBuilder buildNewMatchModal(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    selectedMatchPreset = "Default";

    const double headerTextSize = 18;
    const double inputTextSize = 16;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Padding(
          padding: const EdgeInsets.all(
            8,
          ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 30),
          child: SizedBox(
            height: null,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEW MATCH',
                  style: GoogleFonts.outfit(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: null, //260,
                      width: 350,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ).add(EdgeInsetsGeometry.only(bottom: 10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30),
                            Text(
                              "Opponent",
                              textAlign: TextAlign.left,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: headerTextSize,
                              ),
                            ),
                            SizedBox(height: 7),
                            TextField(
                              controller: _opponentController,
                              autofocus: true,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: inputTextSize,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colors.surfaceContainerHighest,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: colors.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: colors.primary,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Match Preset",
                              textAlign: TextAlign.left,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: headerTextSize,
                              ),
                            ),
                            SizedBox(height: 7),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  minTileHeight: 0,
                                  controller: _matchPresetExpansionController,
                                  title: Text(
                                    selectedMatchPreset,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  expansionAnimationStyle: AnimationStyle(
                                    curve: Curves
                                        .easeOutBack, // This provides the overshoot
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                  trailing: SizedBox.shrink(),
                                  children: ["Default", "LK Turnier"].map((
                                    String value,
                                  ) {
                                    return ListTile(
                                      title: Text(
                                        value,
                                        style: GoogleFonts.outfit(),
                                      ),
                                      onTap: () {
                                        setModalState(() {
                                          selectedMatchPreset = value;
                                        });
                                        _matchPresetExpansionController
                                            .collapse();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 13,
                      left: 13,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'MATCH SETTINGS',
                          style: GoogleFonts.outfit(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  child: OutlinedButton(
                    onPressed: () {
                      final name = _opponentController.text.trim().isEmpty
                          ? null
                          : _opponentController.text.trim();
                      if (name == null) return;

                      final preset = selectedMatchPreset;

                      // Close the modal
                      Navigator.pop(context);

                      // Navigate using the dynamic path
                      // GoRouter automatically handles the string encoding for you
                      router.push("/match/$name/$preset");
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.outline, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'START MATCH',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
