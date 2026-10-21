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

  const ThrowEntry({
    this.id,
    required this.loggedDistance,
    required this.activeWeight,
    required this.projectedDistance,
    required this.timestamp,
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
  final String _onboardingSelectedSex = "M";

  int _onboardingCountryIdx = 0;
  int _onboardingAgeIdx = 3;

  String _activeTimeFilter = "All Time";

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

  // 🎨 Distinct Graded Shades of Premium Scandinavian Moss, Sage, Forest, and Spruce
  final Map<String, Color> _disciplineBackgrounds = {
    'Discus': const Color(0xFF2C3530), // Moss Spruce Shading
    'Shot Put': const Color(0xFF333B36), // Deep Muted Sage
    'Javelin': const Color(0xFF3A443F), // Soft Slate Forest
    'Hammer': const Color(0xFF242B26), // Dense Alpine Timber
    'Weight': const Color(0xFF1E2623), // Glacial Spruce Green
  };

  final Map<String, Color> _disciplineAccents = {
    'Discus': const Color(0xFFACBC9A), // Nordic Moss Highlights
    'Shot Put': const Color(0xFFC2D3B4), // Premium Pale Sage
    'Javelin': const Color(0xFFD2E0BF), // Frost Birch Green
    'Hammer': const Color(0xFF9EB086), // Woodland Leaf Accent
    'Weight': const Color(0xFF8FA89B), // Ice Spruce Highlight
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
    _distanceFieldController.addListener(() {
      setState(() {});
    });
    _initializeAppDatabaseAndProfiles();
  }

  @override
  void dispose() {
    _distanceFieldController.dispose();
    _onboardingNameController.dispose();
    super.dispose();
  }

  // 📐 Core Mathematical Operations
  double _calculateProjectedDistance(
      double distance, double actualW, double standardW) {
    if (actualW == standardW || actualW <= 0) return distance;
    return distance * (actualW / standardW);
  }

  double _getStandardWeight(String discipline, String division) {
    bool isMale = division.startsWith('M');
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
      final profileMaps = await db.getAllProfiles();

      List<UserProfile> loadedProfiles = profileMaps
          .map((m) => UserProfile(
                id: m['id'] as int,
                username: m['username'] as String,
                sex: m['sex'] as String,
                ageGroup: m['ageGroup'] as String,
                country: m.containsKey('country') && m['country'] != null
                    ? (m['country'] as String)
                    : 'United Kingdom (UK)',
              ))
          .toList();

      Map<String, dynamic>? activeMap = await db.getActiveProfile();
      UserProfile? activeUser;

      if (activeMap != null) {
        activeUser = UserProfile(
          id: activeMap['id'] as int,
          username: activeMap['username'] as String,
          sex: activeMap['sex'] as String,
          ageGroup: activeMap['ageGroup'] as String,
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
      debugPrint("Safety database link check bypassed: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedUserThrows() async {
    if (_currentActiveUser == null) return;
    final db = DatabaseHelper.instance;

    for (String discipline in _disciplines) {
      final throwMaps =
          await db.fetchThrowsForUser(_currentActiveUser!.id, discipline);
      List<ThrowEntry> entries = throwMaps
          .map((m) => ThrowEntry(
                id: m['id'] as int?,
                loggedDistance: (m['loggedDistance'] as num).toDouble(),
                activeWeight: (m['activeWeight'] as num).toDouble(),
                projectedDistance: (m['projectedDistance'] as num).toDouble(),
                timestamp: m['timestamp'] as String? ??
                    DateTime.now().toIso8601String(),
              ))
          .toList();

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
        if (tDate.year == currentYear) {
          if (t.loggedDistance > maxSeason) {
            maxSeason = t.loggedDistance;
          }
        }

        if (tDate.isAfter(weekAgo)) weeklyCounter++;
        if (tDate.isAfter(monthAgo)) monthlyCounter++;
        if (tDate.isAfter(yearAgo)) yearlyCounter++;
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

  List _filterDataPointsByTimeWindow(List rawLogs) {
    if (rawLogs.isEmpty) return [];
    final DateTime targetBaselineNow = DateTime.now();
    if (_activeTimeFilter == "Last Session") {
      if (rawLogs.isEmpty) return [];
      final DateTime absoluteLastDate =
          DateTime.tryParse(rawLogs.last.timestamp) ?? targetBaselineNow;
      return rawLogs.where((t) {
        final DateTime tDate =
            DateTime.tryParse(t.timestamp) ?? targetBaselineNow;
        return tDate.day == absoluteLastDate.day &&
            tDate.month == absoluteLastDate.month &&
            tDate.year == absoluteLastDate.year;
      }).toList();
    }
    if (_activeTimeFilter == "Last Week") {
      final limit = targetBaselineNow.subtract(const Duration(days: 7));
      return rawLogs
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    if (_activeTimeFilter == "Last Month") {
      final limit = targetBaselineNow.subtract(const Duration(days: 30));
      return rawLogs
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    if (_activeTimeFilter == "Last Year") {
      final limit = targetBaselineNow.subtract(const Duration(days: 365));
      return rawLogs
          .where((t) => (DateTime.tryParse(t.timestamp) ?? targetBaselineNow)
              .isAfter(limit))
          .toList();
    }
    return rawLogs;
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
        ? const Color(0xFF2C3530)
        : (_activeMenuIndex <= _disciplines.length
            ? _disciplineBackgrounds[_disciplines[_activeMenuIndex - 1]]!
            : const Color(0xFF1E2623));
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                letterSpacing: 2.5)),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              if (value == 'NEW_USER_ACTION') {
                await DatabaseHelper.instance.clearActiveProfile();
                await _initializeAppDatabaseAndProfiles();
              } else {
                int profileId = int.parse(value);
                await DatabaseHelper.instance.setActiveProfile(profileId);
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
                  Icon(Icons.arrow_drop_down, color: currentAccentColor),
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
                          Icons.info_outline, currentAccentColor),
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
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                            left: BorderSide(
                                color: contextCardAccent, width: 4))),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1)),
                            Icon(_getDisciplineIcon(d),
                                color: contextCardAccent, size: 16),
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
                                    fontSize: 18,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text("PB: ${pb.toStringAsFixed(2)}m",
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text("SB: ${sb.toStringAsFixed(2)}m",
                                    style: TextStyle(
                                        fontSize: 10,
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
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E221F),
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
                const Divider(height: 24, color: Colors.white12),
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
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("VISUAL TRAINING DENSITY MATRIX",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white30)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E221F),
                  borderRadius: BorderRadius.circular(12)),
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
                        width: 22,
                        height: 50 * adaptiveHeightFactor,
                        decoration: BoxDecoration(
                          color: const Color(0xFFACBC9A)
                              .withOpacity(0.15 + (index * 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHistoryCounterNode(String subtitle, int count) {
    return Column(
      children: [
        Text("$count",
            style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
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
    final feed = _sessionLogs[discipline]!;
    double standardW = _getStandardWeight(discipline, _selectedDivision);
    double processingW = _customWeightOverrides[discipline] ?? standardW;
    double sessionAvg = feed.isEmpty
        ? 0.0
        : feed.map((e) => e.loggedDistance).reduce((a, b) => a + b) /
            feed.length;
    double todaysBest = 0.0;
    if (feed.isNotEmpty) {
      todaysBest = feed.first.loggedDistance;
      for (var e in feed) {
        if (e.loggedDistance > todaysBest) todaysBest = e.loggedDistance;
      }
    }
    double meritStandard = _getCountryMeritStandard(
        _currentActiveUser?.country ?? 'UK', discipline, _selectedDivision);
    double pb = _lifetimePBs[discipline] ?? 0.0;
    double sb = _seasonsBests[discipline] ?? 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
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
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dynamicAccent.withOpacity(0.3))),
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "${_currentActiveUser?.country.toUpperCase()} NATIONAL MERIT BENCHMARK",
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text("${meritStandard.toStringAsFixed(2)}m",
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            color: dynamicAccent)),
                  ],
                ),
                Text(
                    "Standard: ${standardW.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(12)),
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
                      double proj = _calculateProjectedDistance(
                          loggedDist, processingW, standardW);
                      await DatabaseHelper.instance.insertThrow(
                        userId: _currentActiveUser!.id,
                        discipline: discipline,
                        division: _selectedDivision,
                        loggedDistance: loggedDist,
                        activeWeight: processingW,
                        projectedDistance: proj,
                      );
                      _distanceFieldController.clear();
                      await _loadSavedUserThrows();
                    }
                  },
                ),
              ],
            ),
          ),
          if (processingW != standardW &&
              _distanceFieldController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: dynamicAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                "Estimated projection for standard weight item: ${_calculateProjectedDistance(double.tryParse(_distanceFieldController.text) ?? 0.0, processingW, standardW).toStringAsFixed(2)}m",
                style: TextStyle(
                    color: dynamicAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildThrowLogList(feed, discipline, standardW),
        ],
      ),
    );
  }

  Widget _buildThrowLogList(List feed, String discipline, double standardW) {
    if (feed.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: feed.length,
        itemBuilder: (c, index) {
          final item = feed[feed.length - 1 - index];
          final int globalAttemptNumber = feed.length - index;
          bool hasOverride = item.activeWeight != standardW;
          return ListTile(
            dense: true,
            title: Text("Attempt #$globalAttemptNumber",
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Weight: ${item.activeWeight.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}${hasOverride ? ' (Custom Override)' : ''}",
                style: TextStyle(
                    fontSize: 10,
                    color: hasOverride
                        ? _disciplineAccents[discipline]
                        : Colors.grey)),
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
                          fontSize: 9,
                          color: Colors.white54,
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
    final filteredFeed = _filterDataPointsByTimeWindow(rawFeed);
    double meritStandard = _getCountryMeritStandard(
        _currentActiveUser?.country ?? 'UK', discipline, _selectedDivision);
    final List filterWindows = [
      "All Time",
      "Last Session",
      "Last Week",
      "Last Month",
      "Last Year"
    ];
    double windowMax = 0.0;
    double windowAvg = 0.0;
// 🔹 Fixed: Replaced the un-inferred .reduce() array operator with a simple, standard loop to pull high metrics cleanly
    if (filteredFeed.isNotEmpty) {
      windowMax = filteredFeed.first.loggedDistance;
      double totalSum = 0.0;
      for (var entry in filteredFeed) {
        if (entry.loggedDistance > windowMax) {
          windowMax = entry.loggedDistance;
        }
        totalSum += entry.loggedDistance;
      }
      windowAvg = totalSum / filteredFeed.length;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
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
                            color: isSelected ? Colors.black : Colors.white70)),
                    selected: isSelected,
                    selectedColor: dynamicAccent,
                    backgroundColor: const Color(0xFF1E221F),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _activeTimeFilter = windowName);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text("${_activeTimeFilter.toUpperCase()} TREND GRAPH LINE",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: dynamicAccent,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(12)),
            child: filteredFeed.isEmpty
                ? const Center(
                    child: Text(
                        "No records caught inside this date frame window.",
                        style: TextStyle(fontSize: 11, color: Colors.grey)))
                : CustomPaint(
                    painter: TrainingLineChartPainter(
                        entries: filteredFeed,
                        targetMerit: meritStandard,
                        accentColor: dynamicAccent),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 10, height: 10, color: dynamicAccent),
                const SizedBox(width: 6),
                const Text("Logged Distance",
                    style: TextStyle(fontSize: 11, color: Colors.grey))
              ]),
              Row(children: [
                Container(width: 10, height: 2, color: Colors.white24),
                const SizedBox(width: 6),
                const Text("National Merit Threshold",
                    style: TextStyle(fontSize: 11, color: Colors.grey))
              ]),
            ],
          ),
          const SizedBox(height: 20),
          Text("${_activeTimeFilter.toUpperCase()} CALCULATIONS GRID",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: dynamicAccent,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTimelineStatMiniCard("WINDOW PEAK",
                      "${windowMax.toStringAsFixed(2)}m", dynamicAccent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTimelineStatMiniCard(
                      "WINDOW AVERAGE",
                      "${windowAvg.toStringAsFixed(2)}m",
                      const Color(0xFFEEE3D3))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTimelineStatMiniCard(
                      "TOTAL THROWS", "${filteredFeed.length}", dynamicAccent)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimelineStatMiniCard(
      String label, String value, Color textAccent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  color: textAccent)),
        ],
      ),
    );
  }

  Widget _buildInstructionManualPage(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0xFF1E221F),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ENGINE MATHEMATICS & FEATURES LOG",
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Courier',
                    letterSpacing: 1)),
            const Divider(height: 20, color: Colors.white12),
            _buildManualSectionNode("1. Linear-Inverse Performance Mapping",
                "When logging attempts using custom weight overrides, the engine dynamically estimates performance targets using standard age-group baselines:\n\nFormula: Projected = Logged Distance * (Actual Override Weight / Regional Standard Weight)"),
            _buildManualSectionNode("2. Regional Merit Benchmarks",
                "The horizontal line on your analytics trend chart graphs the BMAF/WMA qualifying thresholds. For instance, an M55 Discus competitor maps against a 29.10m target benchmark line."),
            _buildManualSectionNode("3. Training Density Matrices",
                "The dashboard matrix bars dynamically monitor activity trends based on the logged entries recorded over the rolling 7-day period."),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSectionNode(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white70)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey, height: 1.4)),
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
                          borderRadius: BorderRadius.circular(6),
                        ),
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
                const Text("AGE BAND DIVISION",
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
                          borderRadius: BorderRadius.circular(6),
                        ),
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
                        int id = await db.createProfile(
                            _onboardingNameController.text.trim(),
                            _onboardingSelectedSex,
                            _ageGroupsList[_onboardingAgeIdx],
                            country: _countriesList[_onboardingCountryIdx]);
                        await db.setActiveProfile(id);
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
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paintDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final paintMerit = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final textPaint = TextPainter(textDirection: TextDirection.ltr);
    double maxDistance = targetMerit;
    double minDistance = targetMerit;
    if (entries.isNotEmpty) {
      maxDistance = entries.first.loggedDistance;
      minDistance = entries.first.loggedDistance;
      for (var e in entries) {
        if (e.loggedDistance > maxDistance) maxDistance = e.loggedDistance;
        if (e.loggedDistance < minDistance) minDistance = e.loggedDistance;
      }
    }
    maxDistance = math.max(maxDistance, targetMerit) * 1.15;
    minDistance = math.max(0.0, minDistance - 5.0);
    double range = maxDistance - minDistance;
    if (range <= 0) range = 1.0;
    double meritY =
        size.height - (((targetMerit - minDistance) / range) * size.height);
    canvas.drawLine(Offset(0, meritY), Offset(size.width, meritY), paintMerit);
    textPaint.text = TextSpan(
        text: "Merit: ${targetMerit.toStringAsFixed(1)}m",
        style: const TextStyle(color: Colors.white30, fontSize: 8));
    textPaint.layout();
    textPaint.paint(canvas, Offset(4, meritY - 12));
    double widthSlice = size.width / math.max(1, entries.length - 1);
    List points = [];
    for (int i = 0; i < entries.length; i++) {
      double x = i * widthSlice;
      double y = size.height -
          (((entries[i].loggedDistance - minDistance) / range) * size.height);
      points.add(Offset(x, y));
      canvas.drawCircle(Offset(x, y), 4.0, paintDot);
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
