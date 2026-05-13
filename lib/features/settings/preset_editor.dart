import 'package:ace/features/matches/match_classes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PresetEditorPage extends StatefulWidget {
  const PresetEditorPage({super.key});

  @override
  State<PresetEditorPage> createState() => _PresetEditorPageState();
}

class _PresetEditorPageState extends State<PresetEditorPage> {
  List<MatchPreset> presets = [];
  bool isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('match_presets');

    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        presets = decoded.map((item) => MatchPreset.fromJson(item)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        presets = [
          MatchPreset(id: '1', name: 'Default', setsToWin: 2, gamesPerSet: 6),
          MatchPreset(id: '2', name: 'LK Turnier', setsToWin: 2, useMatchTiebreak: true, matchTiebreakTo: 10),
        ];
        isLoading = false;
      });
      _savePresets();
    }
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(presets.map((p) => p.toJson()).toList());
    await prefs.setString('match_presets', encoded);
  }

  void _updatePreset(MatchPreset updated, int index) {
    setState(() {
      presets[index] = updated;
    });
    _savePresets();
  }

  void _addPreset(MatchPreset newPreset) {
    setState(() {
      presets.add(newPreset);
    });
    _savePresets();
  }

  void _deletePreset(int index) {
    setState(() {
      presets.removeAt(index);
    });
    _savePresets();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MATCH PRESETS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: colors.primary),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      // --- ADD NEW PRESET BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditPresetSheet(
          context,
          MatchPreset(id: _uuid.v4(), name: "New Preset"),
          -1,
        ),
        label: Text("NEW PRESET", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          return _buildPresetCard(context, preset, index);
        },
      ),
    );
  }

  Widget _buildPresetCard(BuildContext context, MatchPreset preset, int index) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  "Best of ${preset.setsToWin} • ${preset.gamesPerSet} Games",
                  style: GoogleFonts.outfit(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          // --- DELETE BUTTON ---
          IconButton(
            onPressed: () {
              // Simple confirmation dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Preset?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                    TextButton(
                      onPressed: () {
                        _deletePreset(index);
                        Navigator.pop(ctx);
                      },
                      child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showEditPresetSheet(context, preset, index),
            icon: Icon(Icons.tune_rounded, color: colors.primary),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPresetSheet(BuildContext context, MatchPreset preset, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _PresetEditSheet(
        preset: preset,
        onSave: (updated) {
          if (index == -1) {
            _addPreset(updated);
          } else {
            _updatePreset(updated, index);
          }
        },
      ),
    );
  }
}

class _PresetEditSheet extends StatefulWidget {
  final MatchPreset preset;
  final Function(MatchPreset) onSave;

  const _PresetEditSheet({required this.preset, required this.onSave});

  @override
  State<_PresetEditSheet> createState() => _PresetEditSheetState();
}

class _PresetEditSheetState extends State<_PresetEditSheet> {
  late TextEditingController _nameController;
  late int gamesPerSet, setsToWin, setTBTo, matchTBTo;
  late bool useSetTB, useMatchTB;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    gamesPerSet = widget.preset.gamesPerSet;
    setsToWin = widget.preset.setsToWin;
    setTBTo = widget.preset.setTiebreakTo;
    matchTBTo = widget.preset.matchTiebreakTo;
    useSetTB = widget.preset.useSetTiebreak;
    useMatchTB = widget.preset.useMatchTiebreak;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 30,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "PRESET SETTINGS",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: colors.primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),

            // Name Field
            _buildSection(context, "NAME", [
              TextField(
                controller: _nameController,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
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
                    borderSide: BorderSide(color: colors.primary, width: 1),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Format Section
            _buildSection(context, "FORMAT", [
              _buildCounter(
                "Sets to Win",
                setsToWin,
                (v) => setState(() => setsToWin = v),
              ),
              _buildCounter(
                "Games per Set",
                gamesPerSet,
                (v) => setState(() => gamesPerSet = v),
              ),
            ]),

            const SizedBox(height: 20),

            // Tiebreak Section
            _buildSection(context, "TIEBREAKS", [
              _buildToggle(
                "Set Tiebreak",
                useSetTB,
                (v) => setState(() => useSetTB = v),
              ),
              if (useSetTB)
                _buildCounter(
                  "Set Tiebreak To",
                  setTBTo,
                  (v) => setState(() => setTBTo = v),
                ),
              const Divider(height: 30),
              _buildToggle(
                "Match Tiebreak",
                useMatchTB,
                (v) => setState(() => useMatchTB = v),
              ),
              if (useMatchTB)
                _buildCounter(
                  "Match Tiebreak To",
                  matchTBTo,
                  (v) => setState(() => matchTBTo = v),
                ),
            ]),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: 350,
              child: OutlinedButton(
                onPressed: () {
                  widget.onSave(
                    MatchPreset(
                      id: widget.preset.id,
                      name: _nameController.text,
                      gamesPerSet: gamesPerSet,
                      setsToWin: setsToWin,
                      useSetTiebreak: useSetTB,
                      setTiebreakTo: setTBTo,
                      useMatchTiebreak: useMatchTB,
                      matchTiebreakTo: matchTBTo,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: colors.primary,
                  side: BorderSide(color: colors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "SAVE PRESET",
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.surface,
            border: Border.all(color: colors.outline),
          ),
          child: Column(children: children),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.transparent,
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: colors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged(value - 1),
              icon: const Icon(Icons.remove_circle_outline, size: 22),
            ),
            Text(
              "$value",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline, size: 22),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
