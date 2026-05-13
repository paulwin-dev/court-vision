import 'package:ace/features/matches/match_classes.dart';
import 'package:ace/routes/router.dart';
import 'package:ace/shared/storage/app_storage.dart';
import "package:flutter/material.dart";
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenPage> {
  final ExpansibleController _matchPresetExpansionController =
      ExpansibleController();
  final TextEditingController _playerController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();

  List<MatchPreset> availablePresets = [];
  late String selectedMatchPresetId;
  late String selectedMatchPresetName;

  late List<Match> allMatches = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPresets();

    AppStorage.getAllMatches().then((list) {
      setState(() {
        allMatches = list;
      });
    });
  }

  Future<void> _loadSavedPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('match_presets');

    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        availablePresets = decoded
            .map((item) => MatchPreset.fromJson(item))
            .toList();
      });
    } else {
      // Default fallback if nothing is saved yet
      setState(() {
        availablePresets = [
          MatchPreset(id: '1', name: 'Default', setsToWin: 2),
          MatchPreset(
            id: '2',
            name: 'LK Turnier',
            setsToWin: 2,
            useMatchTiebreak: true,
          ),
        ];
      });
    }
  }

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
                          itemCount: allMatches.length,
                          itemBuilder: (context, index) {
                            final match = allMatches[index];
                            return GestureDetector(
                              onTap: () => context.push("/stats/${match.id}"),
                              child: Container(
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
                                          "${match.playerName} vs ${match.opponentName}",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          DateFormat.yMd(Localizations.localeOf(context).toString()).format(match.date),
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
                                          match.finalScoreString,
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
                  onPressed: () {
                    context.push("/settings").then((_) => _loadSavedPresets());
                  },
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

    selectedMatchPresetId = availablePresets[0].id;
    selectedMatchPresetName = availablePresets[0].name;

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
                SizedBox(height: 30),
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
                              "Player",
                              textAlign: TextAlign.left,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: headerTextSize,
                              ),
                            ),
                            SizedBox(height: 7),
                            TextField(
                              controller: _playerController,
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
                            SizedBox(height: 7),
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
                                    selectedMatchPresetName,
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
                                  children: availablePresets.isEmpty
                                      ? [
                                          const ListTile(
                                            title: Text("No Presets Found"),
                                          ),
                                        ]
                                      : availablePresets.map((
                                          MatchPreset preset,
                                        ) {
                                          return ListTile(
                                            title: Text(
                                              preset.name,
                                              style: GoogleFonts.outfit(),
                                            ),
                                            subtitle: Text(
                                              "Best of ${preset.setsToWin}",
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                              ),
                                            ),
                                            onTap: () {
                                              setModalState(() {
                                                selectedMatchPresetId = preset.id;
                                                selectedMatchPresetName = preset.name;
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
                      final playerName = _playerController.text.trim().isEmpty
                          ? null
                          : _playerController.text.trim();
                      if (playerName == null) return;

                      final opponentName =
                          _opponentController.text.trim().isEmpty
                          ? null
                          : _opponentController.text.trim();
                      if (opponentName == null) return;

                      final preset = selectedMatchPresetId;

                      Navigator.pop(context);
                      router.push("/match/$playerName/$opponentName/$preset");
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
