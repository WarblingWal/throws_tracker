import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() => runApp(const ThrowsTrackerApp());

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E221F),
          elevation: 0,
        ),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class ThrowEntry {
  final int? id;
  final double loggedDistance;
  final double activeWeight;
  final double projectedDistance;
  final String timestamp;
  final String performanceMode;
  final String techniqueVariant;

  const ThrowEntry({
    this.id,
    required this.loggedDistance,
    required this.activeWeight,
    required this.projectedDistance,
    required this.timestamp,
    required this.performanceMode,
    required this.techniqueVariant,
  });
}

class UserProfile {
  final int id;
  final String username;
  final String sex;
  final String ageGroup;
  final String country;

  UserProfile({
    required this.id,
    required this.username,
    required this.sex,
    required this.ageGroup,
    required this.country,
  });
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  List<UserProfile> _allProfiles = [];
  UserProfile? _currentActiveUser;
  bool _isLoading = true;

  int _activeMenuIndex = 0;
  String _selectedDivision = "M55";
  String _onboardingSelectedSex = "M";

  int _onboardingCountryIdx = 0;
  int _onboardingAgeIdx = 3;

  String _activeTimeFilter = "All Time";
  String _activeModeFilter = "All";
  String _activeTechniqueFilter = "All Techniques";
  String _activeEntryMode = "Training";
  String _activeTechniqueMode = "Standing Throw";
  int _guideSubTab = 0;

  final List<String> _countriesList = [
    'United Kingdom (UK)',
    'United States (US)',
    'Australia',
    'Canada',
    'France',
    'Germany',
    'Ireland',
    'New Zealand',
    'South Africa',
    'Spain'
  ];

  final List<String> _ageGroupsList = [
    'Sch',
    'Sen',
    '50',
    '55',
    '60',
    '65',
    '70',
    '75',
    '80',
    '85',
    '90'
  ];

  final List<String> _disciplines = [
    'Discus',
    'Shot Put',
    'Javelin',
    'Hammer',
    'Weight'
  ];

  final Map<String, List<String>> _implementTechniqueOptions = {
    'Discus': ['Standing Throw', 'Half Turn', 'Full Rotation'],
    'Shot Put': ['Standing Throw', 'Shuffle', 'Glide', 'Rotation'],
    'Javelin': ['Standing Throw', 'Standard Run Up'],
    'Hammer': [
      'Standing Throw',
      '1 Turn',
      '2 Turns',
      '3 Turns',
      '4 Turns',
      '5 Turns'
    ],
    'Weight': [
      'Standing Throw',
      '1 Turn',
      '2 Turns',
      '3 Turns',
      '4 Turns',
      '5 Turns'
    ],
  };

  final Map<String, List<ThrowEntry>> _sessionLogs = {
    'Discus': [],
    'Shot Put': [],
    'Javelin': [],
    'Hammer': [],
    'Weight': []
  };

  final Map<String, double?> _customWeightOverrides = {
    'Discus': null,
    'Shot Put': null,
    'Javelin': null,
    'Hammer': null,
    'Weight': null
  };

  final Map<String, Color> _disciplineBackgrounds = {
    'Discus': const Color(0xFF2C3530),
    'Shot Put': const Color(0xFF333B36),
    'Javelin': const Color(0xFF3A443F),
    'Hammer': const Color(0xFF242B26),
    'Weight': const Color(0xFF1E2623),
  };

  final Map<String, Color> _disciplineAccents = {
    'Discus': const Color(0xFFACBC9A),
    'Shot Put': const Color(0xFFC2D3B4),
    'Javelin': const Color(0xFFD2E0BF),
    'Hammer': const Color(0xFF9EB086),
    'Weight': const Color(0xFF8FA89B),
  };

  final TextEditingController _distanceFieldController =
      TextEditingController();
  final TextEditingController _onboardingNameController =
      TextEditingController();

  final Map<String, double> _lifetimePBs = {
    'Discus': 0.0,
    'Shot Put': 0.0,
    'Javelin': 0.0,
    'Hammer': 0.0,
    'Weight': 0.0
  };

  final Map<String, double> _seasonsBests = {
    'Discus': 0.0,
    'Shot Put': 0.0,
    'Javelin': 0.0,
    'Hammer': 0.0,
    'Weight': 0.0
  };

  String _lastSessionDisplay = "No Workouts Recorded";
  int _weeksCount = 0;
  int _monthsCount = 0;
  int _yearsCount = 0;
  int _pbsThisYearCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAppDatabaseAndProfiles();
  }

  @override
  void dispose() {
    _distanceFieldController.dispose();
    _onboardingNameController.dispose();
    super.dispose();
  }

  double _calculateProjectedDistance(
      double distance, double actualW, double standardW) {
    if (actualW == standardW || actualW <= 0) return distance;
    return distance * (actualW / standardW);
  }

  double _getStandardWeight(String discipline, String division) {
    final bool isMale = division.startsWith('M');
    if (division.contains('55') || division.contains('50')) {
      if (discipline == 'Discus') return isMale ? 1.5 : 1.0;
      if (discipline == 'Shot Put') return isMale ? 6.0 : 3.0;
      if (discipline == 'Javelin') return isMale ? 700.0 : 500.0;
      if (discipline == 'Hammer') return isMale ? 6.0 : 3.0;
      return isMale ? 11.34 : 7.26;
    }
    if (discipline == 'Discus') return isMale ? 2.0 : 1.0;
    if (discipline == 'Shot Put') return isMale ? 7.26 : 4.0;
    if (discipline == 'Javelin') return isMale ? 800.0 : 600.0;
    if (discipline == 'Hammer') return isMale ? 7.26 : 4.0;
    return isMale ? 15.88 : 9.08;
  }

  Future<void> _initializeAppDatabaseAndProfiles() async {
    try {
      final db = DatabaseHelper.instance;
      final profileMaps = await db
          .getUserProfile()
          .then((val) => val != null ? [val] : <Map<String, dynamic>>[]);

      List<UserProfile> loadedProfiles = profileMaps
          .map((m) => UserProfile(
                id: m['id'] as int? ?? 1,
                username: m['name'] as String? ?? 'Athlete',
                sex: 'M',
                ageGroup: '55',
                country: m.containsKey('country') && m['country'] != null
                    ? (m['country'] as String)
                    : 'United Kingdom (UK)',
              ))
          .toList();

      Map<String, dynamic>? activeMap = await db.getUserProfile();
      UserProfile? activeUser;

      if (activeMap != null) {
        activeUser = UserProfile(
          id: activeMap['id'] as int? ?? 1,
          username: activeMap['name'] as String? ?? 'Athlete',
          sex: 'M',
          ageGroup: '55',
          country:
              activeMap.containsKey('country') && activeMap['country'] != null
                  ? (activeMap['country'] as String)
                  : 'United Kingdom (UK)',
        );
      }

      setState(() {
        _allProfiles = loadedProfiles;
        _currentActiveUser = activeUser;
        if (_currentActiveUser != null) {
          _selectedDivision =
              "${_currentActiveUser!.sex}${_currentActiveUser!.ageGroup}";
        }
        _isLoading = false;
      });

      if (_currentActiveUser != null) {
        await _loadSavedUserThrows();
      }
    } catch (e) {
      debugPrint("Database exception caught: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedUserThrows() async {
    if (_currentActiveUser == null) return;
    final db = DatabaseHelper.instance;

    for (String discipline in _disciplines) {
      final throwMaps = await db.getThrowLogs(discipline);
      List<ThrowEntry> entries = throwMaps.map((m) {
        String rawVariant = m['techniqueVariant'] as String? ?? 'Training';
        String modeToken = "Training";
        String techToken = "Standing Throw";

        if (rawVariant.contains('|')) {
          List<String> splits = rawVariant.split('|');
          modeToken = splits[0];
          techToken = splits[1];
        } else {
          modeToken = rawVariant == 'Competition' ? 'Competition' : 'Training';
          techToken = "Standing Throw";
        }

        return ThrowEntry(
          id: m['id'] as int?,
          loggedDistance: (m['distance'] as num).toDouble(),
          activeWeight: _getStandardWeight(discipline, _selectedDivision),
          projectedDistance: (m['distance'] as num).toDouble(),
          timestamp:
              m['dateStamp'] as String? ?? DateTime.now().toIso8601String(),
          performanceMode: modeToken,
          techniqueVariant: techToken,
        );
      }).toList();

      _sessionLogs[discipline] = entries.reversed.toList();
    }
    _recalculateAllMetricsAndLedgers();
  }

  void _recalculateAllMetricsAndLedgers() {
    final int currentYear = DateTime.now().year;
    final DateTime now = DateTime.now();
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    final DateTime monthAgo = now.subtract(const Duration(days: 30));
    final DateTime yearAgo = now.subtract(const Duration(days: 365));

    int weeklyCounter = 0;
    int monthlyCounter = 0;
    int yearlyCounter = 0;
    int pbCounter = 0;
    DateTime? maxTimestamp;
    List<String> lastSessionDisciplines = [];

    for (String d in _disciplines) {
      final throws = _sessionLogs[d] ?? [];
      double maxAllTime = 0.0;
      double maxSeason = 0.0;

      for (var t in throws) {
        DateTime tDate = DateTime.tryParse(t.timestamp) ?? DateTime.now();
        if (maxTimestamp == null || tDate.isAfter(maxTimestamp)) {
          maxTimestamp = tDate;
        }

        if (t.loggedDistance > maxAllTime) {
          maxAllTime = t.loggedDistance;
        }
        if (tDate.year == currentYear && t.loggedDistance > maxSeason) {
          maxSeason = t.loggedDistance;
        }

        if (tDate.isAfter(weekAgo)) {
          weeklyCounter++;
        }
        if (tDate.isAfter(monthAgo)) {
          monthlyCounter++;
        }
        if (tDate.isAfter(yearAgo)) {
          yearlyCounter++;
        }
      }
      _lifetimePBs[d] = maxAllTime;
      _seasonsBests[d] = maxSeason;
      if (maxSeason > 0.0 && maxSeason >= maxAllTime) {
        pbCounter++;
      }
    }
    final DateTime? stableTimestamp = maxTimestamp;
    if (stableTimestamp != null) {
      String dateStr =
          "${stableTimestamp.day.toString().padLeft(2, '0')}/${stableTimestamp.month.toString().padLeft(2, '0')}/${stableTimestamp.year}";
      for (String d in _disciplines) {
        final throws = _sessionLogs[d] ?? [];
        bool thrownThisDay = throws.any((t) {
          DateTime tDate = DateTime.tryParse(t.timestamp) ?? DateTime.now();
          return tDate.day == stableTimestamp.day &&
              tDate.month == stableTimestamp.month &&
              tDate.year == stableTimestamp.year;
        });
        if (thrownThisDay) {
          lastSessionDisciplines
              .add(d.substring(0, math.min(3, d.length)).toUpperCase());
        }
      }
      _lastSessionDisplay = "$dateStr (${lastSessionDisciplines.join(', ')})";
    }
    setState(() {
      _weeksCount = weeklyCounter;
      _monthsCount = monthlyCounter;
      _yearsCount = yearlyCounter;
      _pbsThisYearCount = pbCounter;
    });
  }

  double _getCountryMeritStandard(
      String country, String discipline, String division) {
    bool isMale = division.startsWith('M');
    bool isM55 = division.contains('55');
    if (country.contains('United Kingdom') || country.contains('UK')) {
      if (isM55 && isMale) {
        if (discipline == 'Discus') return 29.10;
        if (discipline == 'Shot Put') return 9.20;
        if (discipline == 'Javelin') return 29.50;
        if (discipline == 'Hammer') return 30.20;
        if (discipline == 'Weight') return 9.40;
      }
      return 25.00;
    }
    return 20.00;
  }

  IconData _getDisciplineIcon(String discipline) {
    if (discipline == 'Discus') return Icons.album;
    if (discipline == 'Shot Put') return Icons.radio_button_checked;
    if (discipline == 'Javelin') return Icons.navigation;
    if (discipline == 'Hammer') return Icons.gavel;
    return Icons.ads_click;
  }

  List _filterDataPoints(List rawLogs) {
    if (rawLogs.isEmpty) return [];
    List workingList = List.from(rawLogs);
    if (_activeModeFilter != "All") {
      workingList = workingList
          .where((t) => t.performanceMode == _activeModeFilter)
          .toList();
    }
    if (_activeTechniqueFilter != "All Techniques") {
      workingList = workingList
          .where((t) => t.techniqueVariant == _activeTechniqueFilter)
          .toList();
    }
    final DateTime targetBaselineNow = DateTime.now();
    if (_activeTimeFilter == "Last Session" && workingList.isNotEmpty) {
      final DateTime absoluteLastDate =
          DateTime.tryParse(workingList.last.timestamp) ?? targetBaselineNow;
      return workingList.where((t) {
        final DateTime tDate =
            DateTime.tryParse(t.timestamp) ?? targetBaselineNow;
        return tDate.day == absoluteLastDate.day &&
            tDate.month == absoluteLastDate.month &&
            tDate.year == absoluteLastDate.year;
      }).toList();
    }
    if (_activeTimeFilter == "Last Week") {
      final limit = targetBaselineNow.subtract(const Duration(days: 7));
      return workingList
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    if (_activeTimeFilter == "Last Month") {
      final limit = targetBaselineNow.subtract(const Duration(days: 30));
      return workingList
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    if (_activeTimeFilter == "Last Year") {
      final limit = targetBaselineNow.subtract(const Duration(days: 365));
      return workingList
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    return workingList;
  }

  Widget _buildSessionVolumeFatigueCurveSection(
      String discipline, Color dynamicAccent) {
    final rawLogs = _sessionLogs[discipline] ?? [];
    if (rawLogs.isEmpty) return const SizedBox.shrink();
    final Map<String, List> datesGroup = {};
    for (var log in rawLogs) {
      if (log.timestamp.length >= 10) {
        final String dayKey = log.timestamp.substring(0, 10);
        datesGroup.putIfAbsent(dayKey, () => []).add(log);
      }
    }
    int totalSessions = 0;
    int peakIndexSum = 0;
    int totalThrowsAfterPeak = 0;
    double postPeakDistanceSum = 0.0;
    double peakDistanceSum = 0.0;
    for (var entries in datesGroup.values) {
      final List linearTimeline = List.from(entries.reversed);
      if (linearTimeline.length >= 2) {
        double maxDistInSession = 0.0;
        int peakIndex = 0;
        for (int i = 0; i < linearTimeline.length; i++) {
          if (linearTimeline[i].loggedDistance > maxDistInSession) {
            maxDistInSession = linearTimeline[i].loggedDistance;
            peakIndex = i + 1;
          }
        }
        totalSessions++;
        peakIndexSum += peakIndex;
        peakDistanceSum += maxDistInSession;
        for (int i = peakIndex; i < linearTimeline.length; i++) {
          totalThrowsAfterPeak++;
          postPeakDistanceSum += linearTimeline[i].loggedDistance;
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
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E221F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: dynamicAccent, size: 16),
              const SizedBox(width: 8),
              const Text('SESSION FATIGUE & PEAK CURVE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            totalSessions > 0
                ? 'Your physical peak performance occurs on average at Throw #$avgPeakThrow of your training workouts.\n\nPerformance shifts down by an average of ${fatigueDropPct.toStringAsFixed(1)}% on later trailing volume logs.'
                : 'Log multiple throws across single dates to plot sequence and drop curves.',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFFEEE3D3), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _build90DayPeakingFinderSection(
      String discipline, Color dynamicAccent) {
    final rawLogs = _sessionLogs[discipline] ?? [];
    final DateTime targetBaselineDate = DateTime(2026, 10, 22);
    final List last90DaysThrows = rawLogs.where((log) {
      final DateTime throwDate =
          DateTime.tryParse(log.timestamp) ?? targetBaselineDate;
      return targetBaselineDate.difference(throwDate).inDays <= 90;
    }).toList();
    last90DaysThrows
        .sort((a, b) => b.loggedDistance.compareTo(a.loggedDistance));
    final List top5Throws = last90DaysThrows.take(5).toList();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E221F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFF3C68F), size: 16),
              SizedBox(width: 8),
              Text('90-DAY PEAKING CYCLE FINDER',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          if (top5Throws.isEmpty)
            const Text(
                'No performance parameters found within the last 90-day training cycle window.',
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else ...[
            const Text('Top 5 Performance Clusters (Last 90 Days):',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ...top5Throws.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "• ${t.loggedDistance.toStringAsFixed(2)}m (${t.performanceMode} - ${t.techniqueVariant})",
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          t.timestamp.length >= 10
                              ? t.timestamp.substring(0, 10)
                              : t.timestamp,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                )),
          ]
        ],
      ),
    );
  }

  Widget _buildImplementWeightDisparitySection(
      String discipline, double standardW) {
    final rawLogs = _sessionLogs[discipline] ?? [];
    double lightSum = 0.0, heavySum = 0.0, standardSum = 0.0;
    int lightCount = 0, heavyCount = 0, standardCount = 0;
    for (var log in rawLogs) {
      if (log.activeWeight < standardW) {
        lightSum += log.loggedDistance;
        lightCount++;
      } else if (log.activeWeight > standardW) {
        heavySum += log.loggedDistance;
        heavyCount++;
      } else {
        standardSum += log.loggedDistance;
        standardCount++;
      }
    }
    if (lightCount == 0 && heavyCount == 0) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1E221F),
            borderRadius: BorderRadius.circular(8)),
        child: const Text(
          'Log throws using Light Implement or Heavy Implement options to calculate power vs velocity mechanics bottlenecks.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E221F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.scale, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text('IMPLEMENT DISPARITY METRIC',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(feedbackMessage,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFEEE3D3), height: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Light Avg: ${lightCount > 0 ? '${(lightSum / lightCount).toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                  "Standard Avg: ${standardCount > 0 ? '${avgStandard.toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                  "Heavy Avg: ${heavyCount > 0 ? '${(heavySum / heavyCount).toStringAsFixed(2)}m' : 'N/A'}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInstructionManualPage(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome to Throws Hub Pro Dashboard',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 6),
          const Text(
            'This interface bridges raw biomechanical outputs with analytical mathematical data models. Use the sub-chips row below to examine operations instructions.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFFEEE3D3), height: 1.4),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: Colors.white12, thickness: 1)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Core Architecture',
                'Fatigue Models',
                'Peaking Finder',
                'Weight Loads'
              ].asMap().entries.map((entry) {
                final bool isSubSelected = _guideSubTab == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSubSelected,
                    selectedColor: accent,
                    labelStyle: TextStyle(
                        color: isSubSelected
                            ? Colors.black
                            : const Color(0xFFEEE3D3),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    backgroundColor: const Color(0xFF1E221F),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _guideSubTab = entry.key);
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
              Column(
                children: [
                  _buildProfessionalManualCard(
                      "1. LINEAR-INVERSE PERFORMANCE MAPPING",
                      "When logging attempts using custom weight overrides, the engine dynamically estimates performance standards side-by-side with logged metrics using standard regional age baselines.",
                      "Formula Configuration Matrix:\nProjected Distance = Logged Distance × (Actual Override Weight / Regional Target Base Weight)",
                      accent),
                  _buildProfessionalManualCard(
                      "2. TRAINING DENSITY GRAPHING MODEL",
                      "The dashboard matrix bars dynamically monitor cumulative activity densities across a rolling 7-day period to display real-time physical workload feedback.",
                      "Data Metric Layout:\nS1 through S7 represent sequential historical segments tracking metrics density clusters across your logged workout counts.",
                      accent),
                ],
              ),
              _buildProfessionalManualCard(
                  "SESSION PEAK & FATIGUE PATTERNS",
                  "Tracks your performance across a single workout to isolate when your body achieves optimal physical power execution. It flags whether you land top metrics at the start, middle, or tail-end of your session volume.",
                  "Workout Structuring Feedback:\nBy tracking chronological drop curves, it provides explicit data to optimize warm-up pacing structures before competitive attempts.",
                  accent),
              _buildProfessionalManualCard(
                  "90-DAY COMPETITION PEAKING BLOCKS",
                  "An automated lookback analysis timeline captures your top 5 longest distances logged across the trailing 90 days from the baseline calendar parameter.",
                  "Nervous System Thresholds:\nEvaluating the distribution of these specific dates reveals physical readiness windows. Tight tracking clusters flag peak competitive readiness.",
                  accent),
              _buildProfessionalManualCard(
                  "RESOLVING PHYSICAL MECHANICS BOTTLENECK",
                  "Maps development thresholds across variable implement loads to pinpoint athletic performance drops and identify whether velocity or force development limits speed.",
                  "Bottleneck Diagnostics:\n• Velocity Bottleneck: Little change with light implement sets indicates a speed restriction.\n• Power Bottleneck: Excessive drop-off using heavy implement items maps a force restriction.",
                  accent),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFACBC9A))));
    }
    if (_currentActiveUser == null) {
      return _buildOnboardingScreen();
    }
    final Color currentCanvasColor = _activeMenuIndex == 0
        ? const Color(0xFF131614)
        : (_activeMenuIndex <= _disciplines.length
            ? _disciplineBackgrounds[_disciplines[_activeMenuIndex - 1]]!
            : const Color(0xFF1A1D1B));
    final Color currentAccentColor = _activeMenuIndex == 0
        ? const Color(0xFFACBC9A)
        : (_activeMenuIndex <= _disciplines.length
            ? _disciplineAccents[_disciplines[_activeMenuIndex - 1]]!
            : const Color(0xFFACBC9A));
    return Scaffold(
      backgroundColor: currentCanvasColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E221F),
        title: const Text('THROWS HUB PRO',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
                letterSpacing: 2.8,
                color: Color(0xFFEEE3D3))),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              if (value == 'NEW_USER_ACTION') {
                await DatabaseHelper.instance
                    .saveUserProfile('', '', 'Shot Put');
                await _initializeAppDatabaseAndProfiles();
              } else {
                await _initializeAppDatabaseAndProfiles();
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Text("${_currentActiveUser!.username} ($_selectedDivision)",
                      style: TextStyle(
                          color: currentAccentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                ..._allProfiles.map((profile) {
                  return PopupMenuItem(
                    value: profile.id.toString(),
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            size: 18,
                            color: profile.id == _currentActiveUser!.id
                                ? currentAccentColor
                                : Colors.grey),
                        const SizedBox(width: 8),
                        Text(profile.username,
                            style: TextStyle(
                                fontWeight: profile.id == _currentActiveUser!.id
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'NEW_USER_ACTION',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: currentAccentColor),
                      const SizedBox(width: 8),
                      Text("New User...",
                          style: TextStyle(color: currentAccentColor)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: Colors.white10),
              Container(
                color: const Color(0xFF1E221F),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTopNavTab(
                          0, 'Overview', Icons.dashboard, currentAccentColor),
                      ...List.generate(_disciplines.length, (index) {
                        final d = _disciplines[index];
                        return _buildTopNavTab(index + 1, d,
                            _getDisciplineIcon(d), currentAccentColor);
                      }),
                      _buildTopNavTab(_disciplines.length + 1, 'System Guide',
                          Icons.help_outline, currentAccentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _activeMenuIndex == 0
          ? _buildDashboardMatrixOverview()
          : (_activeMenuIndex <= _disciplines.length
              ? _buildDisciplineLayout(
                  _disciplines[_activeMenuIndex - 1], currentAccentColor)
              : _buildInstructionManualPage(currentAccentColor)),
    );
  }

  Widget _buildTopNavTab(
      int index, String label, IconData icon, Color dynamicAccent) {
    bool isSelected = _activeMenuIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeMenuIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: isSelected ? dynamicAccent : Colors.transparent,
                    width: 2.5))),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isSelected ? dynamicAccent : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? dynamicAccent : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardMatrixOverview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6),
              itemCount: _disciplines.length,
              itemBuilder: (context, idx) {
                final d = _disciplines[idx];
                final throws = _sessionLogs[d] ?? [];
                final double pb = _lifetimePBs[d] ?? 0.0;
                final double sb = _seasonsBests[d] ?? 0.0;
                final Color contextCardAccent = _disciplineAccents[d]!;
                return GestureDetector(
                  onTap: () => setState(() => _activeMenuIndex = idx + 1),
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E221F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 3)),
                        ]),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d.toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    color: contextCardAccent)),
                            Icon(_getDisciplineIcon(d),
                                color: contextCardAccent, size: 14),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                throws.isEmpty
                                    ? "0.00m"
                                    : "${throws.last.loggedDistance.toStringAsFixed(2)}m",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text("PB: ${pb.toStringAsFixed(2)}m",
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey)),
                                const SizedBox(width: 6),
                                Text("SB: ${sb.toStringAsFixed(2)}m",
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: contextCardAccent
                                            .withOpacity(0.8))),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10, width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Last Active Training Session:",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    Text(_lastSessionDisplay,
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFACBC9A))),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHistoryCounterNode("WEEK", _weeksCount),
                    _buildHistoryCounterNode("MONTH", _monthsCount),
                    _buildHistoryCounterNode("YEAR", _yearsCount),
                    _buildHistoryCounterNode("ANNUAL PBs", _pbsThisYearCount),
                  ],
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("VISUAL TRAINING DENSITY MATRIX",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white30)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 90,
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E221F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final double adaptiveHeightFactor =
                      math.min(1.0, (index + 1) * 0.15 + (_weeksCount * 0.05));
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: math.max(2.0, 45 * adaptiveHeightFactor),
                        decoration: BoxDecoration(
                          color: const Color(0xFFACBC9A)
                              .withOpacity(0.15 + (index * 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("S${index + 1}",
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryCounterNode(String subtitle, int count) {
    return Column(
      children: [
        Text("$count",
            style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDisciplineLayout(String discipline, Color dynamicAccent) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1E221F),
            child: TabBar(
              indicatorColor: dynamicAccent,
              labelColor: dynamicAccent,
              unselectedLabelColor: const Color(0xFF6C7075),
              tabs: const [
                Tab(
                    child: Text("Current Session",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
                Tab(
                    child: Text("Historical Analytics",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCurrentSessionView(discipline, dynamicAccent),
                _buildHistoricalChartsView(discipline, dynamicAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionView(String discipline, Color dynamicAccent) {
    final List rawFeed = _sessionLogs[discipline]!;
    final List filteredFeed = rawFeed
        .where((t) =>
            _activeModeFilter == "All" ||
            t.performanceMode == _activeModeFilter)
        .toList();
    double standardW = _getStandardWeight(discipline, _selectedDivision);
    double processingW = _customWeightOverrides[discipline] ?? standardW;
    double sessionAvg = filteredFeed.isEmpty
        ? 0.0
        : filteredFeed.map((e) => e.loggedDistance).reduce((a, b) => a + b) /
            filteredFeed.length;
    double todaysBest = 0.0;
    if (filteredFeed.isNotEmpty) {
      todaysBest = filteredFeed.first.loggedDistance;
      for (var e in filteredFeed) {
        if (e.loggedDistance > todaysBest) {
          todaysBest = e.loggedDistance;
        }
      }
    }
    double pb = _lifetimePBs[discipline] ?? 0.0;
    double sb = _seasonsBests[discipline] ?? 0.0;
    List validTechniques =
        _implementTechniqueOptions[discipline] ?? ['Standing Throw'];
    if (!validTechniques.contains(_activeTechniqueMode)) {
      _activeTechniqueMode = validTechniques.first;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ["All", "Training", "Competition"].map((m) {
              bool isSelected = _activeModeFilter == m;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0, bottom: 10.0),
                child: ChoiceChip(
                  label: Text(m,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white)),
                  selected: isSelected,
                  selectedColor: dynamicAccent,
                  backgroundColor: const Color(0xFF1E221F),
                  onSelected: (s) => setState(() => _activeModeFilter = m),
                ),
              );
            }).toList(),
          ),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPanelStatNode("TODAYS BEST",
                    "${todaysBest.toStringAsFixed(2)}m", dynamicAccent),
                _buildPanelStatNode(
                    "SESSION AVG",
                    "${sessionAvg.toStringAsFixed(2)}m",
                    const Color(0xFFEEE3D3)),
                _buildPanelStatNode(
                    "LIFETIME PB", "${pb.toStringAsFixed(2)}m", dynamicAccent),
                _buildPanelStatNode("SEASONS BEST", "${sb.toStringAsFixed(2)}m",
                    const Color(0xFFEEE3D3)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BIOMECHANICAL TECHNIQUE SELECTION",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: validTechniques.map((tech) {
                      bool active = _activeTechniqueMode == tech;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(tech,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: active ? Colors.black : Colors.white)),
                          selected: active,
                          selectedColor: dynamicAccent,
                          backgroundColor: const Color(0xFF2C302E),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _activeTechniqueMode = tech);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: _distanceFieldController,
            builder: (context, val, child) {
              final double? parseValue = double.tryParse(val.text);
              if (processingW != standardW &&
                  parseValue != null &&
                  parseValue > 0) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: dynamicAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "Estimated projection for standard weight item: ${_calculateProjectedDistance(parseValue, processingW, standardW).toStringAsFixed(2)}m",
                    style: TextStyle(
                        color: dynamicAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier'),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Expanded(
                    child: Text("IMPLEMENT SELECTION OVERRIDE",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey))),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => setState(() {
                    double current =
                        _customWeightOverrides[discipline] ?? standardW;
                    _customWeightOverrides[discipline] =
                        (current - (discipline == 'Javelin' ? 50 : 0.25))
                            .clamp(0.1, 5000.0);
                  }),
                ),
                Text(
                    "${processingW.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => setState(() {
                    double current =
                        _customWeightOverrides[discipline] ?? standardW;
                    _customWeightOverrides[discipline] =
                        current + (discipline == 'Javelin' ? 50 : 0.25);
                  }),
                ),
                if (_customWeightOverrides[discipline] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: InkWell(
                      onTap: () => setState(
                          () => _customWeightOverrides[discipline] = null),
                      child:
                          Icon(Icons.refresh, color: dynamicAccent, size: 20),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ENTRY CLASSIFICATION MODE",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Row(
                  children: ["Training", "Competition"].map((mode) {
                    bool active = _activeEntryMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              active ? dynamicAccent : const Color(0xFF2C302E),
                          foregroundColor: active ? Colors.black : Colors.white,
                          textStyle: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () =>
                            setState(() => _activeEntryMode = mode),
                        child: Text(mode.toUpperCase()),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distanceFieldController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 15, fontFamily: 'Courier'),
                    decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF2C3530),
                        labelText: 'Distance (meters)',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.send, color: dynamicAccent),
                  onPressed: () async {
                    double loggedDist =
                        double.tryParse(_distanceFieldController.text) ?? 0.0;
                    if (loggedDist > 0.0 && _currentActiveUser != null) {
                      FocusScope.of(context).unfocus();
                      String packedVariant =
                          "$_activeEntryMode|$_activeTechniqueMode";
                      await DatabaseHelper.instance.insertThrowLog(
                        discipline,
                        packedVariant,
                        loggedDist,
                        DateTime.now().toIso8601String(),
                      );
                      _distanceFieldController.clear();
                      await _loadSavedUserThrows();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildThrowLogList(filteredFeed, discipline, standardW),
        ],
      ),
    );
  }

  Widget _buildThrowLogList(List feed, String discipline, double standardW) {
    if (feed.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: feed.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.white12),
        itemBuilder: (c, index) {
          final item = feed[feed.length - 1 - index];
          final int globalAttemptNumber = feed.length - index;
          bool hasOverride = item.activeWeight != standardW;
          return ListTile(
            dense: true,
            leading: Icon(
                item.performanceMode == 'Competition'
                    ? Icons.emoji_events
                    : Icons.fitness_center,
                size: 14,
                color: Colors.white30),
            title: Text(
                "Attempt #$globalAttemptNumber [${item.performanceMode}]",
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Style: ${item.techniqueVariant} | Wt: ${item.activeWeight.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                style: const TextStyle(fontSize: 11, color: Color(0xFF909499))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${item.loggedDistance.toStringAsFixed(2)}m",
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                if (hasOverride)
                  Text("Est: ${item.projectedDistance.toStringAsFixed(2)}m",
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF909499),
                          fontFamily: 'Courier')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoricalChartsView(String discipline, Color dynamicAccent) {
    final rawFeed = _sessionLogs[discipline] ?? [];
    final filteredFeed = _filterDataPoints(rawFeed);
    double meritStandard = _getCountryMeritStandard(
        _currentActiveUser?.country ?? 'UK', discipline, _selectedDivision);
    final List filterWindows = [
      "All Time",
      "Last Session",
      "Last Week",
      "Last Month",
      "Last Year"
    ];
    List validTechniques = [
      "All Techniques",
      ...(_implementTechniqueOptions[discipline] ?? [])
    ];
    if (!validTechniques.contains(_activeTechniqueFilter)) {
      _activeTechniqueFilter = "All Techniques";
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListExpandedDelegate([
              TimeFilterRow(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterWindows.map((windowName) {
                      bool isSelected = _activeTimeFilter == windowName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(windowName,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70)),
                          selected: isSelected,
                          selectedColor: dynamicAccent,
                          backgroundColor: const Color(0xFF1E221F),
                          onSelected: (s) =>
                              setState(() => _activeTimeFilter = windowName),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: validTechniques.map((techName) {
                    bool isSelected = _activeTechniqueFilter == techName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(techName,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.black : Colors.grey)),
                        selected: isSelected,
                        selectedColor: dynamicAccent.withOpacity(0.8),
                        backgroundColor: const Color(0xFF1E221F),
                        onSelected: (s) =>
                            setState(() => _activeTechniqueFilter = techName),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                  "${_activeTimeFilter.toUpperCase()} ANALYTICS MATRIX GRAPH ($_activeTechniqueFilter)",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dynamicAccent,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                height: 240,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E221F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10)),
                child: filteredFeed.isEmpty
                    ? const Center(
                        child: Text(
                            "No records caught inside this date frame window filter configuration.",
                            style: TextStyle(fontSize: 11, color: Colors.grey)))
                    : CustomPaint(
                        painter: TrainingLineChartPainter(
                            entries: filteredFeed,
                            targetMerit: meritStandard,
                            accentColor: dynamicAccent)),
              ),
              _buildSessionVolumeFatigueCurveSection(discipline, dynamicAccent),
              _build90DayPeakingFinderSection(discipline, dynamicAccent),
              _buildImplementWeightDisparitySection(discipline,
                  _getStandardWeight(discipline, _selectedDivision)),
            ]),
          ),
        )
      ],
    );
  }

  Widget _buildProfessionalManualCard(
      String title, String summary, String details, Color accentColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFamily: 'Courier',
                  letterSpacing: 1)),
          const Divider(height: 16, color: Colors.white12),
          Text(summary,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFEEE3D3), height: 1.4)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            child: Text(details,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                    fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CREATE ATHLETE PROFILE",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEEE3D3),
                        fontFamily: 'Courier')),
                const SizedBox(height: 16),
                TextField(
                  controller: _onboardingNameController,
                  style: const TextStyle(fontFamily: 'Courier'),
                  decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF2C3530),
                      labelText: "Username / Name"),
                ),
                const SizedBox(height: 20),
                const Text("GENDER DESIGNATION BAND",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Male (M)",
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: _onboardingSelectedSex == "M",
                      selectedColor: const Color(0xFFACBC9A),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _onboardingSelectedSex = "M");
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("Female (F)",
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: _onboardingSelectedSex == "F",
                      selectedColor: const Color(0xFFACBC9A),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _onboardingSelectedSex = "F");
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("ATHLETIC NATION ORIGIN",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_countriesList.length, (idx) {
                    bool isSel = _onboardingCountryIdx == idx;
                    return InkWell(
                      onTap: () => setState(() => _onboardingCountryIdx = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFACBC9A)
                                : const Color(0xFF2C3530),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(_countriesList[idx],
                            style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text("AGE DIVISION DESIGNATION",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_ageGroupsList.length, (idx) {
                    bool isSel = _onboardingAgeIdx == idx;
                    return InkWell(
                      onTap: () => setState(() => _onboardingAgeIdx = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFACBC9A)
                                : const Color(0xFF2C3530),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(_ageGroupsList[idx],
                            style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFACBC9A)),
                    onPressed: () async {
                      if (_onboardingNameController.text.trim().isNotEmpty) {
                        final db = DatabaseHelper.instance;
                        await db.saveUserProfile(
                            _onboardingNameController.text.trim(),
                            _countriesList[_onboardingCountryIdx],
                            'Shot Put');
                        _onboardingNameController.clear();
                        await _initializeAppDatabaseAndProfiles();
                      }
                    },
                    child: const Text("INITIALIZE ACCOUNT",
                        style: TextStyle(
                            color: Color(0xFF131516),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelStatNode(String label, String value, Color textAccent) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF909499),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                color: textAccent)),
      ],
    );
  }
}

class TrainingLineChartPainter extends CustomPainter {
  final List entries;
  final double targetMerit;
  final Color accentColor;
  TrainingLineChartPainter(
      {required this.entries,
      required this.targetMerit,
      required this.accentColor});
  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final paintLine = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paintDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final paintAxis = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    final paintMerit = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final textPaint = TextPainter(textDirection: TextDirection.ltr);
    double maxDistance = targetMerit;
    double minDistance = targetMerit;
    for (var e in entries) {
      if (e.loggedDistance > maxDistance) maxDistance = e.loggedDistance;
      if (e.loggedDistance < minDistance) minDistance = e.loggedDistance;
    }
    maxDistance = math.max(maxDistance, targetMerit) * 1.15;
    minDistance = math.max(0.0, minDistance - 4.0);
    double range = maxDistance - minDistance;
    if (range <= 0) range = 1.0;
    int lineCount = 4;
    for (int i = 0; i <= lineCount; i++) {
      double factor = i / lineCount;
      double yPos = size.height - (factor * size.height);
      double val = minDistance + (factor * range);
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paintAxis);
      textPaint.text = TextSpan(
          text: "${val.toStringAsFixed(1)}m",
          style: const TextStyle(color: Colors.white38, fontSize: 8));
      textPaint.layout();
      textPaint.paint(canvas, Offset(-26, yPos - 5));
    }
    double meritY =
        size.height - (((targetMerit - minDistance) / range) * size.height);
    canvas.drawLine(Offset(0, meritY), Offset(size.width, meritY), paintMerit);
    textPaint.text = TextSpan(
        text: "MERIT: ${targetMerit.toStringAsFixed(1)}m",
        style: TextStyle(
            color: accentColor.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.bold));
    textPaint.layout();
    textPaint.paint(canvas, Offset(4, meritY - 12));
    double widthSlice = size.width / math.max(1, entries.length - 1);
    List points = [];
    for (int i = 0; i < entries.length; i++) {
      double x = i * widthSlice;
      double y = size.height -
          (((entries[i].loggedDistance - minDistance) / range) * size.height);
      points.add(Offset(x, y));
      canvas.drawCircle(Offset(x, y), 3.5, paintDot);
    }
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paintLine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TimeFilterRow extends StatelessWidget {
  final Widget child;
  const TimeFilterRow({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class SliverChildListExpandedDelegate extends SliverChildDelegate {
  final List children;
  SliverChildListExpandedDelegate(this.children);
  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) return null;
    return children[index];
  }

  @override
  int get estimatedChildCount => children.length;
  @override
  bool shouldRebuild(covariant SliverChildListExpandedDelegate oldDelegate) =>
      true;
}
