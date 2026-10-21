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
          backgroundColor: const Color(0xFF1E221F),
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
  String _onboardingSelectedSex = "M";
  String _onboardingSelectedAge = "55";
  String _onboardingSelectedCountry = "United Kingdom (UK)";

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

  // Dynamic Theme Matrix mapping unique Scandinavian background tones per implement
  final Map<String, Color> _disciplineBackgrounds = {
    'Discus': const Color(0xFF2C3530), // Rich Organic Moss
    'Shot Put': const Color(0xFF222B28), // Charcoal Slate-Moss
    'Javelin': const Color(0xFF343F36), // Deep Forest Sage
    'Hammer': const Color(0xFF3A3E36), // Muted Organic Umber
    'Weight': const Color(0xFF1E2623), // Deep Alpine Spruce
  };

  // Nav bar accent highlight matching arrays
  final Map<String, Color> _disciplineAccents = {
    'Discus': const Color(0xFFACBC9A), // Pale Premium Sage
    'Shot Put': const Color(0xFF9DB2A4), // Silver Moss Silver
    'Javelin': const Color(0xFFB1C7A3), // Bright Leaf Green
    'Hammer': const Color(0xFFC2C5A9), // Raw Wheat Umber
    'Weight': const Color(0xFF8FA89B), // Ice Alpine Teal
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

  Future<void> _initializeAppDatabaseAndProfiles() async {
    final db = DatabaseHelper.instance;
    final profileMaps = await db.getAllProfiles();

    List<UserProfile> loadedProfiles = profileMaps
        .map((m) => UserProfile(
              id: m['id'] as int,
              username: m['username'] as String,
              sex: m['sex'] as String,
              ageGroup: m['ageGroup'] as String,
              country: m.containsKey('country')
                  ? (m['country'] as String? ?? 'United Kingdom (UK)')
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
        country: activeMap.containsKey('country')
            ? (activeMap['country'] as String? ?? 'United Kingdom (UK)')
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

      _sessionLogs[discipline] = entries;
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

        if (t.loggedDistance > maxAllTime) maxAllTime = t.loggedDistance;
        if (tDate.year == currentYear) {
          if (t.loggedDistance > maxSeason) maxSeason = t.loggedDistance;
        }

        if (tDate.isAfter(weekAgo)) weeklyCounter++;
        if (tDate.isAfter(monthAgo)) monthlyCounter++;
        if (tDate.isAfter(yearAgo)) yearlyCounter++;
      }

      _lifetimePBs[d] = maxAllTime;
      _seasonsBests[d] = maxSeason;
      if (maxSeason > 0.0 && maxSeason >= maxAllTime) pbCounter++;
    }

    if (maxTimestamp != null) {
      String dateStr =
          "${maxTimestamp.day.toString().padLeft(2, '0')}/${maxTimestamp.month.toString().padLeft(2, '0')}/${maxTimestamp.year}";
      for (String d in _disciplines) {
        final throws = _sessionLogs[d] ?? [];
        bool thrownThisDay = throws.any((t) {
          DateTime tDate = DateTime.tryParse(t.timestamp) ?? DateTime.now();
          return tDate.day == maxTimestamp!.day &&
              tDate.month == maxTimestamp!.month &&
              tDate.year == maxTimestamp!.year;
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

  double _calculateProjectedDistance(
      double distance, double actualW, double standardW) {
    if (actualW == standardW || actualW <= 0) return distance;
    return distance * (actualW / standardW);
  }

  double _getCountryMeritStandard(
      String country, String discipline, String division) {
    bool isMale = division.startsWith('M');
    bool isM55 = division.contains('55');
    if (country.contains('United Kingdom') || country.contains('UK')) {
      if (isM55 && isMale) {
        if (discipline == 'Discus')
          return 29.10; // Official British BMAF M55 Merit Standard
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFACBC9A))));
    if (_currentActiveUser == null) return _buildOnboardingScreen();

    final Color currentCanvasColor = _activeMenuIndex == 0
        ? const Color(0xFF2C3530)
        : _disciplineBackgrounds[_disciplines[_activeMenuIndex - 1]]!;
    final Color currentAccentColor = _activeMenuIndex == 0
        ? const Color(0xFFACBC9A)
        : _disciplineAccents[_disciplines[_activeMenuIndex - 1]]!;

    return Scaffold(
      backgroundColor: currentCanvasColor,
      appBar: AppBar(
        title: const Text('THROWS HUB PRO',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                letterSpacing: 2)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF1E221F),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTopNavTab(
                      0, 'Overview', Icons.dashboard, currentAccentColor),
                  ...List.generate(_disciplines.length, (index) {
                    final d = _disciplines[index];
                    return _buildTopNavTab(index + 1, d, _getDisciplineIcon(d),
                        currentAccentColor);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _activeMenuIndex == 0
          ? _buildDashboardMatrixOverview()
          : _buildDisciplineLayout(
              _disciplines[_activeMenuIndex - 1], currentAccentColor),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
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
                          left:
                              BorderSide(color: contextCardAccent, width: 4))),
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
                                      color:
                                          contextCardAccent.withOpacity(0.8))),
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
          const SizedBox(height: 20),
          const Text("HISTORICAL WORKOUT STATS & PROGRESSION",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFACBC9A))),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Last Active Training Session:",
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
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
          )
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
                const Center(child: Text("Analytics Section")),
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
    double todaysBest =
        feed.isEmpty ? 0.0 : feed.map((e) => e.loggedDistance).reduce(math.max);
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
                      child: const Icon(Icons.refresh,
                          color: Colors.redAccent, size: 20),
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
          const SizedBox(height: 14),
          _buildThrowLogList(feed, discipline),
        ],
      ),
    );
  }

  Widget _buildThrowLogList(List feed, String discipline) {
    if (feed.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: feed.length,
        itemBuilder: (c, index) {
          final item = feed[feed.length - 1 - index];
          final int globalAttemptNumber = feed.length - index;
          return ListTile(
            dense: true,
            title: Text("Attempt #$globalAttemptNumber",
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Weight: ${item.activeWeight.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                style: const TextStyle(fontSize: 10)),
            trailing: Text("${item.loggedDistance.toStringAsFixed(2)}m",
                style: const TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          );
        },
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    List ages = [
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
                const SizedBox(height: 16),
                const Text("ATHLETIC NATION ORIGIN",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                DropdownButton(
                  value: _onboardingSelectedCountry,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E221F),
                  style: const TextStyle(
                      color: Color(0xFFACBC9A), fontWeight: FontWeight.bold),
                  onChanged: (v) =>
                      setState(() => _onboardingSelectedCountry = v!),
                  items: _countriesList
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                DropdownButton(
                  value: _onboardingSelectedAge,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E221F),
                  style: const TextStyle(
                      color: Color(0xFFACBC9A), fontWeight: FontWeight.bold),
                  onChanged: (v) =>
                      setState(() => _onboardingSelectedAge = v as String),
                  items: ages
                      .map((a) => DropdownMenuItem(
                          value: a, child: Text("Age Group: $a")))
                      .toList(),
                ),
                const SizedBox(height: 24),
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
                            _onboardingSelectedAge,
                            country: _onboardingSelectedCountry);
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
