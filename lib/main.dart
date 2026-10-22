import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThrowsTrackerApp());
}

class ThrowsTrackerApp extends StatelessWidget {
  const ThrowsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Throws Hub Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFACBC9A),
        cardColor: const Color(0xFF1E221F),
        scaffoldBackgroundColor: const Color(0xFF131614),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFEEE3D3),
              displayColor: const Color(0xFFEEE3D3),
              fontSizeDelta: 1.2,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E221F),
          elevation: 0,
        ),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedNavigationIndex = 0;
  int _guideSubTab = 0;
  bool _isUserInitialized = false;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedCountry;

  // Exact authorized top choice chips matrix sequence
  final List<String> _navigationTabs = [
    'Overview',
    'Discus',
    'Shot Put',
    'Javelin',
    'Hammer',
    'Weight',
    'System Guide'
  ];

  final Map<String, Color> _disciplineAccents = {
    'Overview': const Color(0xFF9AA7BC),
    'Discus': const Color(0xFFBC9A9A),
    'Shot Put': const Color(0xFFACBC9A),
    'Javelin': const Color(0xFFBCBA9A),
    'Hammer': const Color(0xFF9ABABC),
    'Weight': const Color(0xFFB19ABC),
    'System Guide': const Color(0xFFACBC9A),
  };

  final Map<String, Color> _disciplineBackgrounds = {
    'Overview': const Color(0xFF1E2022),
    'Discus': const Color(0xFF221E1E),
    'Shot Put': const Color(0xFF1E221F),
    'Javelin': const Color(0xFF22221E),
    'Hammer': const Color(0xFF1E2222),
    'Weight': const Color(0xFF201E22),
    'System Guide': const Color(0xFF1E221F),
  };

  List<Map<String, dynamic>> _throwHistory = [];
  final TextEditingController _distanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final user = await DatabaseHelper.instance.getUserProfile();
      if (user != null) {
        setState(() {
          _nameController.text = user['name'] ?? '';
          _selectedCountry = user['country'];
          _isUserInitialized = true;
        });
        await _loadThrowLogs();
      }
    } catch (e) {
      debugPrint("Profile validation channel error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadThrowLogs() async {
    final String activeRoute = _navigationTabs[_selectedNavigationIndex];
    if (activeRoute == 'System Guide') return;

    final logs = await DatabaseHelper.instance
        .getThrowLogs(activeRoute == 'Overview' ? 'Shot Put' : activeRoute);
    setState(() {
      _throwHistory = logs;
    });
  }

  Future<void> _initializeAccount() async {
    if (_nameController.text.trim().isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please supply both your name and training country location.')),
      );
      return;
    }

    await DatabaseHelper.instance.saveUserProfile(
      _nameController.text.trim(),
      _selectedCountry!,
      'Shot Put',
    );

    setState(() {
      _isUserInitialized = true;
    });
    await _loadThrowLogs();
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131614),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              const Text(
                'Select Training Country',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEEE3D3)),
              ),
              const Divider(color: Colors.white12, height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _onboardingCountries.length,
                  itemBuilder: (context, index) {
                    final country = _onboardingCountries[index];
                    final bool showDivider = country == 'Switzerland';

                    return Column(
                      children: [
                        ListTile(
                          title: Text(country,
                              style: const TextStyle(color: Color(0xFFEEE3D3))),
                          trailing: _selectedCountry == country
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFFACBC9A))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        if (showDivider)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(
                                color: Color(0xFFACBC9A),
                                thickness: 1.5,
                                height: 20),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logNewThrow() async {
    final String activeRoute = _navigationTabs[_selectedNavigationIndex];
    final double? dist = double.tryParse(_distanceController.text);
    if (dist == null || dist <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please supply a valid numeric performance distance metric.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedVariant = 'Full Rotation';
        if (activeRoute == 'Shot Put' || activeRoute == 'Overview') {
          selectedVariant = 'Glide';
        }
        if (activeRoute == 'Javelin') selectedVariant = '5-Step Approach';

        final List<String> variants =
            (activeRoute == 'Shot Put' || activeRoute == 'Overview')
                ? [
                    'Standing Throw',
                    'Glide',
                    'Rotation',
                    'Light Implement (-1kg)',
                    'Heavy Implement (+1kg)'
                  ]
                : (activeRoute == 'Discus' ||
                        activeRoute == 'Hammer' ||
                        activeRoute == 'Weight')
                    ? [
                        'Standing Throw',
                        'Half Turn',
                        'Full Rotation',
                        'Light Implement (-1kg)',
                        'Heavy Implement (+1kg)'
                      ]
                    : [
                        'Standing Throw',
                        'Short Approach',
                        '5-Step Approach',
                        'Light Implement (-100g)',
                        'Heavy Implement (+100g)'
                      ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E221F),
              title: const Text('Select Execution Variant',
                  style: TextStyle(color: Color(0xFFEEE3D3))),
              content: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E221F),
                value: selectedVariant,
                isExpanded: true,
                items: variants
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v,
                            style: const TextStyle(color: Color(0xFFEEE3D3)))))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedVariant = val!),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _disciplineAccents[activeRoute]),
                  onPressed: () async {
                    await DatabaseHelper.instance.insertThrowLog(
                      activeRoute == 'Overview' ? 'Shot Put' : activeRoute,
                      selectedVariant,
                      dist,
                      DateTime.now().toIso8601String(),
                    );
                    _distanceController.clear();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    await _loadThrowLogs();
                  },
                  child: const Text('Save Log',
                      style: TextStyle(color: Color(0xFF131614))),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTechniqueEfficiencyMatrixTable() {
    final Map<String, List<double>> groupedDistances = {};
    for (var log in _throwHistory) {
      final String variant = log['techniqueVariant'] ?? 'Unknown';
      final double dist = log['distance'] ?? 0.0;
      groupedDistances.putIfAbsent(variant, () => []).add(dist);
    }
    final double baselineAvg = (groupedDistances['Standing Throw'] != null &&
            groupedDistances['Standing Throw']!.isNotEmpty)
        ? groupedDistances['Standing Throw']!.reduce((a, b) => a + b) /
            groupedDistances['Standing Throw']!.length
        : 0.0;
    return Table(
      border: TableBorder.all(
          color: Colors.white12,
          width: 1,
          borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
          children: const [
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Technique',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Count',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Avg (m)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Eff Delta',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        ...groupedDistances.entries.map((entry) {
          final double avg =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
          String deltaText = 'Baseline';
          Color deltaColor = Colors.grey;
          if (entry.key != 'Standing Throw' && baselineAvg > 0) {
            final double delta = avg - baselineAvg;
            deltaText = "${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}m";
            deltaColor =
                delta >= 0 ? const Color(0xFFACBC9A) : Colors.redAccent;
          }
          return TableRow(
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(entry.key, style: const TextStyle(fontSize: 12))),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${entry.value.length}',
                      style: const TextStyle(fontSize: 12))),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(avg.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(deltaText,
                    style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAdvancedSessionAnalysisView(String currentAccentRoute) {
    if (_throwHistory.isEmpty) return const SizedBox.shrink();
    final Map<String, List<Map<String, dynamic>>> datesGroup = {};
    for (var log in _throwHistory) {
      final String fullDate = log['dateStamp'] ?? '';
      if (fullDate.length >= 10) {
        final String dayKey = fullDate.substring(0, 10);
        datesGroup.putIfAbsent(dayKey, () => []).add(log);
      }
    }
    int totalSessions = 0;
    int peakIndexSum = 0;
    int totalThrowsAfterPeak = 0;
    double postPeakDistanceSum = 0.0;
    double peakDistanceSum = 0.0;
    for (var entries in datesGroup.values) {
      final List<Map<String, dynamic>> linearTimeline =
          List.from(entries.reversed);
      if (linearTimeline.length >= 2) {
        double maxDistInSession = 0.0;
        int peakIndex = 0;
        for (int i = 0; i < linearTimeline.length; i++) {
          final double distanceVal = linearTimeline[i]['distance'] ?? 0.0;
          if (distanceVal > maxDistInSession) {
            maxDistInSession = distanceVal;
            peakIndex = i + 1;
          }
        }
        totalSessions++;
        peakIndexSum += peakIndex;
        peakDistanceSum += maxDistInSession;
        for (int i = peakIndex; i < linearTimeline.length; i++) {
          totalThrowsAfterPeak++;
          postPeakDistanceSum += linearTimeline[i]['distance'] ?? 0.0;
        }
      }
    }
    final int avgPeakThrow =
        totalSessions > 0 ? (peakIndexSum / totalSessions).round() : 0;
    double fatigueDropPct = 0.0;
    if (totalThrowsAfterPeak > 0 && totalSessions > 0) {
      final double baselinePeakAvg = peakDistanceSum / totalSessions;
      final double trailingAvg = postPeakDistanceSum / totalThrowsAfterPeak;
      if (baselinePeakAvg > trailingAvg) {
        fatigueDropPct =
            ((baselinePeakAvg - trailingAvg) / baselinePeakAvg) * 100;
      }
    }
    final DateTime targetBaselineDate = DateTime(2026, 10, 22);
    final List<Map<String, dynamic>> last90DaysThrows =
        _throwHistory.where((log) {
      final String dateStr = log['dateStamp'] ?? '';
      if (dateStr.isEmpty) return false;
      final DateTime throwDate =
          DateTime.tryParse(dateStr) ?? targetBaselineDate;
      return targetBaselineDate.difference(throwDate).inDays <= 90;
    }).toList();
    last90DaysThrows.sort(
        (a, b) => (b['distance'] as double).compareTo(a['distance'] as double));
    final List<Map<String, dynamic>> top5Throws =
        last90DaysThrows.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E221F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    _disciplineAccents[currentAccentRoute]!.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt,
                      color: _disciplineAccents[currentAccentRoute], size: 20),
                  const SizedBox(width: 8),
                  const Text('SESSION FATIGUE & PEAK CURVE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                totalSessions > 0
                    ? 'Your physical peak performance occurs on average at Throw #$avgPeakThrow of your training workouts.\n\nPerformance shifts down by an average of ${fatigueDropPct.toStringAsFixed(1)}% on later trailing volume logs.'
                    : 'Log multiple throws across single dates to plot sequence and drop curves.',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFEEE3D3), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E221F),
            borderRadius: BorderRadius.circular(12),
            border:
                const Border.fromBorderSide(BorderSide(color: Colors.white12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFFF3C68F), size: 20),
                  SizedBox(width: 8),
                  Text('90-DAY PEAKING CYCLE FINDER',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              if (top5Throws.isEmpty)
                const Text(
                    'No performance parameters found within the last 90-day training cycle window.',
                    style: TextStyle(color: Colors.white38, fontSize: 13))
              else ...[
                const Text('Top 5 Performance Clusters (Last 90 Days):',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                ...top5Throws.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "• ${t['distance'].toStringAsFixed(2)}m (${t['techniqueVariant']})",
                              style: const TextStyle(fontSize: 13)),
                          Text(t['dateStamp'].toString().substring(0, 10),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white38)),
                        ],
                      ),
                    )),
              ]
            ],
          ),
        )
      ],
    );
  }

  Widget _buildImplementDisparityView() {
    double lightSum = 0.0, heavySum = 0.0, standardSum = 0.0;
    int lightCount = 0, heavyCount = 0, standardCount = 0;
    for (var log in _throwHistory) {
      final String variant = log['techniqueVariant'] ?? '';
      final double dist = log['distance'] ?? 0.0;
      if (variant.contains('Light')) {
        lightSum += dist;
        lightCount++;
      } else if (variant.contains('Heavy')) {
        heavySum += dist;
        heavyCount++;
      } else if (variant != 'Unknown') {
        standardSum += dist;
        standardCount++;
      }
    }
    if (lightCount == 0 && heavyCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1E221F),
            borderRadius: BorderRadius.circular(12)),
        child: const Text(
          'Log throws using Light Implement or Heavy Implement options to calculate power vs velocity mechanics bottlenecks.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }
    final double avgStandard =
        standardCount > 0 ? standardSum / standardCount : 0.0;
    String feedbackMessage =
        "Log standard variance vectors alongside modified elements to resolve bottlenecks.";
    if (avgStandard > 0) {
      final double avgLight = lightCount > 0 ? lightSum / lightCount : 0.0;
      final double avgHeavy = heavyCount > 0 ? heavySum / heavyCount : 0.0;
      if (avgLight > 0 && (avgLight - avgStandard) < (avgStandard * 0.05)) {
        feedbackMessage =
            "⚠️ Velocity Bottleneck Detected: Your distance changes insignificantly with a lighter implement. Focus on quick acceleration dynamics.";
      } else if (avgHeavy > 0 &&
          (avgStandard - avgHeavy) > (avgStandard * 0.15)) {
        feedbackMessage =
            "⚠️ Power Bottleneck Detected: Heavy implement distances show rapid decay profiles. Focus on foundational force development and heavy release metrics.";
      } else {
        feedbackMessage =
            "✅ Balanced Development: Power thresholds and release velocity mechanics are shifting proportionally across variable loads.";
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E221F),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.scale, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text('IMPLEMENT DISPARITY METRIC',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(feedbackMessage,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFEEE3D3), height: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Light Avg: ${lightCount > 0 ? '${(lightSum / lightCount).toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                  "Standard Avg: ${standardCount > 0 ? '${avgStandard.toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                  "Heavy Avg: ${heavyCount > 0 ? '${(heavySum / heavyCount).toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSystemGuideDashboardView(Color currentAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome to Throws Hub Pro Dashboard',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: currentAccent),
        ),
        const SizedBox(height: 8),
        const Text(
          'This interactive framework bridges raw execution metrics with analytical sports data modeling. Toggle the control chips below to review operational rules.',
          style: TextStyle(fontSize: 13, color: Color(0xFFEEE3D3), height: 1.4),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: Divider(color: Colors.white12, thickness: 1),
        ),
// Sub-Tab Switcher Node Layout
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'System Overview',
              'Session Curves',
              'Peaking Blocks',
              'Weight Loads'
            ].asMap().entries.map((entry) {
              final bool isSubSelected = _guideSubTab == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: isSubSelected,
                  selectedColor: currentAccent,
                  labelStyle: TextStyle(
                      color: isSubSelected
                          ? const Color(0xFF131614)
                          : const Color(0xFFEEE3D3),
                      fontSize: 11),
                  backgroundColor: const Color(0xFF1E221F),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _guideSubTab = entry.key;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        IndexedStack(
          index: _guideSubTab,
          children: [
            Card(
              color: const Color(0xFF1E221F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('HOW TO OPERATE THE ARTIFACT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentAccent)),
                    const SizedBox(height: 12),
                    const Text(
                        '1. Log Throw Volumes: Select any discipline focus layout on the top navigation bar to input metric configurations or load variables.',
                        style: TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    const Text(
                        '2. Swipe-to-Delete: Swipe items sideways inside the tracking ledger list to perform immediate localized database purge routines.',
                        style: TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    const Text(
                        '3. Review Analytics: Core metrics automate technique variation matrices, sequence peak values, and fatigue ratio deltas underneath your history lists.',
                        style: TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ),
            Card(
              color: const Color(0xFF1E221F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('SESSION PEAK & FATIGUE PATTERNS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentAccent)),
                    const SizedBox(height: 12),
                    const Text(
                      'Tracks your performance across a single workout to identify exactly when your body reaches its optimal physical peak. It answers the critical training question: “Do I throw my best distances at the beginning, middle, or end of my session?”\n\nBy constructing chronological drop curves, it provides explicit data to optimize warm-up structures before competitive attempts.',
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFFEEE3D3)),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: const Color(0xFF1E221F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('90-DAY COMPETITION PEAKING BLOCKS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentAccent)),
                    const SizedBox(height: 12),
                    const Text(
                      'An analysis timeline captures your top 5 longest distances logged across the trailing 90 days.\n\nEvaluating the distribution of these specific dates reveals physical readiness windows. Tight tracking clusters tell coaches and athletes that neuromuscular output thresholds are peaked and prepared for championship events.',
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFFEEE3D3)),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: const Color(0xFF1E221F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('RESOLVING PHYSICAL MECHANICS BOTTLENECK',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentAccent)),
                    const SizedBox(height: 12),
                    const Text(
                      'Maps development thresholds across variable implement loads to pinpoint athletic performance bottlenecks:\n\n• Velocity Bottleneck: Modest improvement with lighter implements reveals speed restrictions.\n• Power Bottleneck: Excessive distance decay on heavy loads tracks raw force limitations.',
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFFEEE3D3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFACBC9A))));
    }
    if (!_isUserInitialized) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.fitness_center,
                    size: 64, color: Color(0xFFACBC9A)),
                const SizedBox(height: 16),
                const Text('THROWS HUB PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const Text('Athlete Profiling & Metric Analytics Engine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Athlete Full Name',
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFFACBC9A)),
                    filled: true,
                    fillColor: const Color(0xFF1E221F),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Training Country / Region',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(
                    _selectedCountry ?? 'Tap to select country...',
                    style: TextStyle(
                        fontSize: 16,
                        color: _selectedCountry != null
                            ? const Color(0xFFEEE3D3)
                            : Colors.white38,
                        fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFFACBC9A)),
                  tileColor: const Color(0xFF1E221F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => _showCountryPicker(context),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFACBC9A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _initializeAccount,
                  child: const Text('INITIALIZE ACCOUNT',
                      style: TextStyle(
                          color: Color(0xFF131614),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final String activeRouteName = _navigationTabs[_selectedNavigationIndex];
    final Color currentAccent = _disciplineAccents[activeRouteName]!;
    final Color currentCardBg = _disciplineBackgrounds[activeRouteName]!;
    final bool isGuideActive = activeRouteName == 'System Guide';
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isGuideActive ? 'System Guide Hub' : 'Throws Hub: $activeRouteName',
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        actions: [
          if (!isGuideActive)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: () async => await _loadThrowLogs(),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
// Top Selection Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _navigationTabs.map((discipline) {
                  final bool isSelected = activeRouteName == discipline;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(discipline),
                      selected: isSelected,
                      selectedColor: _disciplineAccents[discipline],
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF131614)
                            : const Color(0xFFEEE3D3),
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xFF1E221F),
                      onSelected: (selected) async {
                        if (selected) {
                          setState(() {
                            _selectedNavigationIndex =
                                _navigationTabs.indexOf(discipline);
                          });
                          await _loadThrowLogs();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
// Layout View Switcher Node
            isGuideActive
                ? _buildSystemGuideDashboardView(currentAccent)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: currentCardBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _distanceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Measured Metric Distance (m)',
                                    labelStyle: TextStyle(
                                        color: currentAccent.withOpacity(0.8)),
                                    border: const UnderlineInputBorder(),
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: currentAccent)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              FloatingActionButton(
                                backgroundColor: currentAccent,
                                foregroundColor: const Color(0xFF131614),
                                onPressed: _logNewThrow,
                                child: const Icon(Icons.add),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('HISTORICAL LOG ENTRIES',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: Colors.grey)),
                          Text('${_throwHistory.length} Recorded',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_throwHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                              'No historical parameters mapped across this discipline execution track.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _throwHistory.length,
                          itemBuilder: (context, index) {
                            final item = _throwHistory[index];
                            final int id = item['id'];
                            return Dismissible(
                              key: Key('throw_entry$id'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) async {
                                await DatabaseHelper.instance
                                    .deleteThrowLog(id);
                                setState(() {
                                  _throwHistory.removeAt(index);
                                });
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Log element purged successfully.')),
                                );
                              },
                              child: Card(
                                color: const Color(0xFF1E221F),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        currentAccent.withOpacity(0.1),
                                    child: Icon(Icons.analytics,
                                        color: currentAccent),
                                  ),
                                  title: Text("${item['distance']} meters",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  subtitle: Text(
                                      "${item['techniqueVariant']} • ${item['dateStamp'].toString().split('T')}"),
                                ),
                              ),
                            );
                          },
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Divider(color: Colors.white12, thickness: 1.5),
                      ),
                      _buildTechniqueEfficiencyMatrixTable(),
                      const SizedBox(height: 24),
                      _buildAdvancedSessionAnalysisView(activeRouteName),
                      const SizedBox(height: 24),
                      _buildImplementDisparityView(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

final List _onboardingCountries = [
  'United States',
  'United Kingdom',
  'Germany',
  'France',
  'Italy',
  'Spain',
  'Netherlands',
  'Sweden',
  'Norway',
  'Finland',
  'Denmark',
  'Ireland',
  'Poland',
  'Austria',
  'Belgium',
  'Switzerland',
  'Afghanistan',
  'Albania',
  'Algeria',
  'Andorra',
  'Angola',
  'Antigua and Barbuda',
  'Argentina',
  'Armenia',
  'Australia',
  'Azerbaijan',
  'Bahamas',
  'Bahrain',
  'Bangladesh',
  'Barbados',
  'Belarus',
  'Belize',
  'Benin',
  'Bhutan',
  'Bolivia',
  'Bosnia and Herzegovina',
  'Botswana',
  'Brazil',
  'Brunei',
  'Bulgaria',
  'Burkina Faso',
  'Burundi',
  'Cabo Verde',
  'Cambodia',
  'Cameroon',
  'Canada',
  'Central African Republic',
  'Chad',
  'Chile',
  'China',
  'Colombia',
  'Comoros',
  'Congo (Brazzaville)',
  'Congo (Kinshasa - DRC)',
  'Costa Rica',
  'Croatia',
  'Cuba',
  'Cyprus',
  'Czech Republic',
  'Djibouti',
  'Dominica',
  'Dominican Republic',
  'East Timor',
  'Ecuador',
  'Egypt',
  'El Salvador',
  'Equatorial Guinea',
  'Eritrea',
  'Estonia',
  'Eswatini',
  'Ethiopia',
  'Fiji',
  'Gabon',
  'Gambia',
  'Georgia',
  'Ghana',
  'Greece',
  'Grenada',
  'Guatemala',
  'Guinea',
  'Guinea-Bissau',
  'Word',
  'Haiti',
  'Honduras',
  'Hungary',
  'Iceland',
  'India',
  'Indonesia',
  'Iran',
  'Iraq',
  'Israel',
  'Ivory Coast',
  'Jamaica',
  'Japan',
  'Jordan',
  'Kazakhstan',
  'Kenya',
  'Kiribati',
  'Kuwait',
  'Kyrgyzstan',
  'Laos',
  'Latvia',
  'Lebanon',
  'Lesotho',
  'Liberia',
  'Libya',
  'Liechtenstein',
  'Lithuania',
  'Luxembourg',
  'Madagascar',
  'Malawi',
  'Malaysia',
  'Maldives',
  'Mali',
  'Malta',
  'Marshall Islands',
  'Mauritania',
  'Mauritius',
  'Mexico',
  'Micronesia',
  'Moldova',
  'Monaco',
  'Mongolia',
  'Montenegro',
  'Morocco',
  'Mozambique',
  'Myanmar',
  'Namibia',
  'Nauru',
  'Nepal',
  'New Zealand',
  'Nicaragua',
  'Niger',
  'Nigeria',
  'North Korea',
  'North Macedonia',
  'Oman',
  'Pakistan',
  'Palau',
  'Palestine',
  'Panama',
  'Papua New Guinea',
  'Paraguay',
  'Peru',
  'Philippines',
  'Portugal',
  'Qatar',
  'Romania',
  'Russia',
  'Rwanda',
  'Saint Kitts and Nevis',
  'Saint Lucia',
  'Saint Vincent',
  'Samoa',
  'San Marino',
  'Sao Tome and Principe',
  'Saudi Arabia',
  'Senegal',
  'Serbia',
  'Seychelles',
  'Sierra Leone',
  'Singapore',
  'Slovakia',
  'Slovenia',
  'Solomon Islands',
  'Somalia',
  'South Africa',
  'South Korea',
  'South Sudan',
  'Sri Lanka',
  'Sudan',
  'Suriname',
  'Syria',
  'Taiwan',
  'Tajikistan',
  'Tanzania',
  'Thailand',
  'Togo',
  'Tonga',
  'Trinidad and Tobago',
  'Tunisia',
  'Turkey',
  'Turkmenistan',
  'Tuvalu',
  'Uganda',
  'Ukraine',
  'United Arab Emirates',
  'Uruguay',
  'Uzbekistan',
  'Vanuatu',
  'Vatican City',
  'Venezuela',
  'Vietnam',
  'Yemen',
  'Zambia',
  'Zimbabwe'
];
