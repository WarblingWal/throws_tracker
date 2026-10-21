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

class ThrowEntry {
  final int? id;
  final double loggedDistance;
  final double activeWeight;
  final double projectedDistance;
  final String timestamp;
  final String performanceMode;
  final String technique;

  const ThrowEntry({
    this.id,
    required this.loggedDistance,
    required this.activeWeight,
    required this.projectedDistance,
    required this.timestamp,
    required this.performanceMode,
    required this.technique,
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
  bool _isAddingNewUser = false;

  int _activeMenuIndex = 0;
  String _selectedDivision = "M55";

  String _activeTimeFilter = "All Time";
  String _activeModeFilter = "All";
  String _activeTechniqueFilter = "All Techniques";
  String _activeEntryMode = "Training";
  String _activeEntryTechnique = "Standing Throw";

  final TextEditingController _onboardingNameController =
      TextEditingController();
  String _onboardingSelectedSex = "M";
  int _onboardingCountryIdx = 0;
  int _onboardingAgeIdx = 5;

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
    'Spain',
    'Italy',
    'Netherlands',
    'Sweden',
    'Norway',
    'Finland',
    'Denmark',
    'Japan',
    'China',
    'Brazil',
    'Argentina',
    'Jamaica',
    'Poland',
    'Czechia'
  ];

  final List<String> _ageGroupsList = [
    'Sch',
    'Sen',
    '35',
    '40',
    '45',
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

  final Map<String, List<String>> _disciplineTechniques = {
    'Discus': ['Standing Throw', 'Half Rotation', 'Full Rotation'],
    'Shot Put': ['Standing Throw', 'Shuffle', 'Glide', 'Rotation'],
    'Javelin': ['Standing Throw', 'Run Up'],
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

  final Map<String, double> _trainingPBs = {
    'Discus': 0.0,
    'Shot Put': 0.0,
    'Javelin': 0.0,
    'Hammer': 0.0,
    'Weight': 0.0
  };
  final Map<String, double> _competitionPBs = {
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
  final Map<String, double> _monthlyAverages = {
    'Discus': 0.0,
    'Shot Put': 0.0,
    'Javelin': 0.0,
    'Hammer': 0.0,
    'Weight': 0.0
  };
  final Map<String, int> _throwsThisYearCount = {
    'Discus': 0,
    'Shot Put': 0,
    'Javelin': 0,
    'Hammer': 0,
    'Weight': 0
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
    if (actualW == standardW || actualW <= 0) {
      return distance;
    }
    return distance * (actualW / standardW);
  }

  double _getStandardWeight(String discipline, String division) {
    final bool isMale = division.startsWith('M');
    if (division.contains('55') || division.contains('50')) {
      if (discipline == 'Discus') {
        return isMale ? 1.5 : 1.0;
      }
      if (discipline == 'Shot Put') {
        return isMale ? 6.0 : 3.0;
      }
      if (discipline == 'Javelin') {
        return isMale ? 700.0 : 500.0;
      }
      if (discipline == 'Hammer') {
        return isMale ? 6.0 : 3.0;
      }
      return isMale ? 11.34 : 7.26;
    }
    if (discipline == 'Discus') {
      return isMale ? 2.0 : 1.0;
    }
    if (discipline == 'Shot Put') {
      return isMale ? 7.26 : 4.0;
    }
    if (discipline == 'Javelin') {
      return isMale ? 800.0 : 600.0;
    }
    if (discipline == 'Hammer') {
      return isMale ? 7.26 : 4.0;
    }
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
      } else if (loadedProfiles.isNotEmpty) {
        activeUser = loadedProfiles.first;
        await db.setActiveProfile(activeUser.id);
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
    if (_currentActiveUser == null) {
      return;
    }
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
                performanceMode:
                    m.containsKey('division') && m['division'] == 'Competition'
                        ? 'Competition'
                        : 'Training',
                technique: m.containsKey('technique') && m['technique'] != null
                    ? (m['technique'] as String)
                    : 'Standing Throw',
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
      double maxTraining = 0.0;
      double maxCompetition = 0.0;
      double maxSeason = 0.0;
      double monthlySum = 0.0;
      int monthlyCount = 0;
      int annualCount = 0;
      for (var t in throws) {
        DateTime tDate = DateTime.tryParse(t.timestamp) ?? DateTime.now();
        if (maxTimestamp == null || tDate.isAfter(maxTimestamp)) {
          maxTimestamp = tDate;
        }
        if (t.performanceMode == 'Training') {
          if (t.loggedDistance > maxTraining) {
            maxTraining = t.loggedDistance;
          }
        } else if (t.performanceMode == 'Competition') {
          if (t.loggedDistance > maxCompetition) {
            maxCompetition = t.loggedDistance;
          }
        }
        if (tDate.year == currentYear) {
          annualCount++;
          if (t.loggedDistance > maxSeason) {
            maxSeason = t.loggedDistance;
          }
        }
        if (tDate.isAfter(monthAgo)) {
          monthlySum += t.loggedDistance;
          monthlyCount++;
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
      _trainingPBs[d] = maxTraining;
      _competitionPBs[d] = maxCompetition;
      _seasonsBests[d] = maxSeason;
      _monthlyAverages[d] =
          monthlyCount > 0 ? (monthlySum / monthlyCount) : 0.0;
      _throwsThisYearCount[d] = annualCount;
      double maxOverall = math.max(maxTraining, maxCompetition);
      if (maxSeason > 0.0 && maxSeason >= maxOverall) {
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
    } else {
      _lastSessionDisplay = "No Workouts Recorded";
    }
    setState(() {
      _weeksCount = weeklyCounter;
      _monthsCount = monthlyCounter;
      _yearsCount = yearlyCounter;
      _pbsThisYearCount = pbCounter;
    });
  }

  List _filterDataPoints(List rawLogs) {
    if (rawLogs.isEmpty) {
      return [];
    }
    List workingList = List.from(rawLogs);
    if (_activeTechniqueFilter != "All Techniques") {
      workingList = workingList
          .where((t) => t.technique == _activeTechniqueFilter)
          .toList();
    }
    if (_activeModeFilter != "All") {
      workingList = workingList
          .where((t) => t.performanceMode == _activeModeFilter)
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

  IconData _getDisciplineIcon(String discipline) {
    if (discipline == 'Discus') {
      return Icons.album;
    }
    if (discipline == 'Shot Put') {
      return Icons.radio_button_checked;
    }
    if (discipline == 'Javelin') {
      return Icons.navigation;
    }
    if (discipline == 'Hammer') {
      return Icons.gavel;
    }
    return Icons.ads_click;
  }

  double _getCountryMeritStandard(
      String country, String discipline, String division) {
    bool isMale = division.startsWith('M');
    bool isM55 = division.contains('55');
    if (country.contains('United Kingdom') || country.contains('UK')) {
      if (isM55 && isMale) {
        if (discipline == 'Discus') {
          return 29.10;
        }
        if (discipline == 'Shot Put') {
          return 9.20;
        }
        if (discipline == 'Javelin') {
          return 29.50;
        }
        if (discipline == 'Hammer') {
          return 30.20;
        }
        if (discipline == 'Weight') {
          return 9.40;
        }
      }
      return 25.00;
    }
    return 20.00;
  }

  void _showProfileSelectionModal() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E221F),
          title: const Text("SELECT ACTIVE ATHLETE PROFILE",
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _allProfiles.length + 1,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                if (index == _allProfiles.length) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.add, color: Color(0xFFACBC9A)),
                    title: const Text("Create New Profile...",
                        style: TextStyle(
                            color: Color(0xFFACBC9A),
                            fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _isAddingNewUser = true);
                    },
                  );
                }
                final profile = _allProfiles[index];
                final bool isActive = _currentActiveUser != null &&
                    profile.id == _currentActiveUser!.id;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.person,
                      color: isActive ? const Color(0xFFACBC9A) : Colors.grey),
                  title: Text(profile.username,
                      style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(
                      "${profile.sex}${profile.ageGroup} | ${profile.country}",
                      style: const TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await DatabaseHelper.instance.setActiveProfile(profile.id);
                    await _initializeAppDatabaseAndProfiles();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFACBC9A))));
    }
    if (_currentActiveUser == null || _isAddingNewUser) {
      return _buildFlatOnboardingView(canCancel: _currentActiveUser != null);
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
                letterSpacing: 2.8,
                color: Color(0xFFEEE3D3))),
        actions: [
          TextButton.icon(
            onPressed: _showProfileSelectionModal,
            icon: Icon(Icons.arrow_drop_down, color: currentAccentColor),
            label: Text(
              "${_currentActiveUser!.username} ($_selectedDivision)",
              style: TextStyle(
                  color: currentAccentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
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
                    fontSize: 13,
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E221F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Last Active Training Session:",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    Text(_lastSessionDisplay,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFACBC9A))),
                  ],
                ),
                const Divider(height: 20, color: Colors.white24),
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
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Divider(color: Colors.white12, thickness: 1.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 0.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15),
              itemCount: _disciplines.length,
              itemBuilder: (context, idx) {
                final d = _disciplines[idx];
                final double trPB = _trainingPBs[d] ?? 0.0;
                final double compPB = _competitionPBs[d] ?? 0.0;
                final double sb = _seasonsBests[d] ?? 0.0;
                final double avgDist = _monthlyAverages[d] ?? 0.0;
                final int yearThrows = _throwsThisYearCount[d] ?? 0;
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
                              offset: Offset(0, 3))
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
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    color: contextCardAccent)),
                            Icon(_getDisciplineIcon(d),
                                color: contextCardAccent, size: 14),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("T-PB: ${trPB.toStringAsFixed(2)}m",
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text("C-PB: ${compPB.toStringAsFixed(2)}m",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    color: contextCardAccent)),
                            const SizedBox(height: 4),
                            Text(
                                "SB: ${sb.toStringAsFixed(2)}m | Avg: ${avgDist.toStringAsFixed(1)}m",
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                            Text("Throws This Year: $yearThrows",
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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
                        height: 45 * adaptiveHeightFactor,
                        decoration: BoxDecoration(
                          color: const Color(0xFFACBC9A)
                              .withOpacity(0.15 + (index * 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("S${index + 1}",
                          style: const TextStyle(
                              fontSize: 10,
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
                fontSize: 22,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                            fontWeight: FontWeight.bold, fontSize: 14))),
                Tab(
                    child: Text("Historical Analytics",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14))),
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
    double trPB = _trainingPBs[discipline] ?? 0.0;
    double coPB = _competitionPBs[discipline] ?? 0.0;
    double sb = _seasonsBests[discipline] ?? 0.0;
    List validTechs = _disciplineTechniques[discipline]!;
    if (!validTechs.contains(_activeEntryTechnique)) {
      _activeEntryTechnique = validTechs.first;
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
                padding: const EdgeInsets.only(right: 6.0, bottom: 6.0),
                child: Theme(
                  data: ThemeData.dark()
                      .copyWith(canvasColor: Colors.transparent),
                  child: ChoiceChip(
                    label: Text(m,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: dynamicAccent,
                    onSelected: (s) => setState(() => _activeModeFilter = m),
                  ),
                ),
              );
            }).toList(),
          ),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E221F),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPanelStatNode("TODAYS BEST",
                        "${todaysBest.toStringAsFixed(2)}m", dynamicAccent),
                    _buildPanelStatNode(
                        "SESSION AVG",
                        "${sessionAvg.toStringAsFixed(2)}m",
                        const Color(0xFFEEE3D3)),
                  ],
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(color: Colors.white12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPanelStatNode("TRAIN PB",
                        "${trPB.toStringAsFixed(2)}m", dynamicAccent),
                    _buildPanelStatNode("COMP PB",
                        "${coPB.toStringAsFixed(2)}m", dynamicAccent),
                    _buildPanelStatNode("SEASON BEST",
                        "${sb.toStringAsFixed(2)}m", const Color(0xFFEEE3D3)),
                  ],
                )
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
                      color: dynamicAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "EST: ${_calculateProjectedDistance(parseValue, processingW, standardW).toStringAsFixed(2)}m",
                    style: TextStyle(
                        color: dynamicAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
                    child: Text("IMPLEMENT WEIGHT OVERRIDE",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey))),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
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
                          Icon(Icons.refresh, color: dynamicAccent, size: 22),
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
                const Text("ENTRY CLASSIFICATION",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Row(
                  children: ["Training", "Competition"].map((m) {
                    bool active = _activeEntryMode == m;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              active ? dynamicAccent : const Color(0xFF2C302E),
                          foregroundColor: active ? Colors.black : Colors.white,
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => setState(() => _activeEntryMode = m),
                        child: Text(m.toUpperCase()),
                      ),
                    );
                  }).toList(),
                )
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
                const Text("EXECUTION TECHNIQUE",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: validTechs.map((tech) {
                      bool isSelected = _activeEntryTechnique == tech;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Theme(
                          data: ThemeData.dark()
                              .copyWith(canvasColor: Colors.transparent),
                          child: ChoiceChip(
                            label: Text(tech,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white70)),
                            selected: isSelected,
                            selectedColor: dynamicAccent,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _activeEntryTechnique = tech);
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                    style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
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
                      String activeTech = _disciplineTechniques[discipline]!
                              .contains(_activeEntryTechnique)
                          ? _activeEntryTechnique
                          : _disciplineTechniques[discipline]!.first;
                      await DatabaseHelper.instance.insertThrow(
                        userId: _currentActiveUser!.id,
                        discipline: discipline,
                        division: _activeEntryMode,
                        loggedDistance: loggedDist,
                        activeWeight: processingW,
                        projectedDistance: proj,
                        technique: activeTech,
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
    if (feed.isEmpty) {
      return const SizedBox();
    }
    double meritStandard = _getCountryMeritStandard(
        _currentActiveUser?.country ?? 'UK', discipline, _selectedDivision);
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
          bool exceedsMerit = item.loggedDistance >= meritStandard;
          Color leadingIconColor =
              exceedsMerit ? const Color(0xFF4CAF50) : Colors.white30;
          return Dismissible(
            key: Key(item.id?.toString() ?? 'throw_${index}_${item.timestamp}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              color: const Color(0xFFFF5252),
              child: const Icon(Icons.delete_forever, color: Colors.white),
            ),
            onDismissed: (direction) async {
              if (item.id != null) {
                final db = DatabaseHelper.instance;
                bool codeDeleted = await db.deleteThrow(item.id!);
                if (codeDeleted) {
                  await _loadSavedUserThrows();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Throw entry removed successfully from database storage."),
                        backgroundColor: Color(0xFF1E221F),
                      ),
                    );
                  }
                }
              }
            },
            child: ListTile(
              dense: true,
              leading: Icon(
                  item.performanceMode == 'Competition'
                      ? Icons.emoji_events
                      : Icons.fitness_center,
                  size: 16,
                  color: leadingIconColor),
              title: Text(
                  "Attempt #$globalAttemptNumber [${item.performanceMode}] - ${item.technique}",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Weight: ${item.activeWeight.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}${hasOverride ? ' (Override)' : ''}",
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF909499))),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item.loggedDistance.toStringAsFixed(2)}m",
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (hasOverride)
                    Text("Est: ${item.projectedDistance.toStringAsFixed(2)}m",
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF909499),
                            fontFamily: 'Courier')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechniqueEfficiencyMatrixTable(String discipline, Color accent) {
    final List throws = _sessionLogs[discipline] ?? [];
    if (throws.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text("No records caught to process comparative metrics tables.",
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    double standingAvg = 0.0;
    int standingCount = 0;
    final Map<String, List> nonStandingLogs = {};
    for (var t in throws) {
      if (t.technique == 'Standing Throw') {
        standingAvg += t.loggedDistance;
        standingCount++;
      } else {
        nonStandingLogs
            .putIfAbsent(t.technique, () => [])
            .add(t.loggedDistance);
      }
    }
    if (standingCount > 0) {
      standingAvg /= standingCount;
    }
    if (nonStandingLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
            "Log advanced execution variants to view delta analytics curves.",
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10)),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.2),
        },
        border: const TableBorder(
            horizontalInside: BorderSide(color: Colors.white12, width: 1)),
        children: [
// 🛡️ Fix applied: Swapped raw parameter for explicit BoxDecoration token wrapper
          TableRow(
            decoration: const BoxDecoration(color: Colors.black26),
            children: [
              _buildTableCellLabel("TECHNIQUE VARIANT",
                  isHeader: true, textColor: accent),
              _buildTableCellLabel("COUNT",
                  isHeader: true, textColor: Colors.grey),
              _buildTableCellLabel("AVG DIST",
                  isHeader: true, textColor: Colors.grey),
              _buildTableCellLabel("EFF DELTA",
                  isHeader: true, textColor: accent),
            ],
          ),
          ...nonStandingLogs.entries.map((entry) {
            final String techName = entry.key;
            final List distances = entry.value;
            final double techAvg =
                distances.reduce((a, b) => a + b) / distances.length;
            double deltaValue = 0.0;
            double percentageGain = 0.0;
            if (standingAvg > 0) {
              deltaValue = techAvg - standingAvg;
              percentageGain = (deltaValue / standingAvg) * 100;
            }
            String deltaStr = "0.00m";
            Color deltaColor = Colors.grey;
            if (deltaValue > 0) {
              deltaStr =
                  "+${deltaValue.toStringAsFixed(2)}m (+${percentageGain.toStringAsFixed(1)}%)";
              deltaColor = const Color(0xFF4CAF50);
            } else if (deltaValue < 0) {
              deltaStr =
                  "${deltaValue.toStringAsFixed(2)}m (${percentageGain.toStringAsFixed(1)}%)";
              deltaColor = const Color(0xFFFF5252);
            }
            return TableRow(
              children: [
                _buildTableCellLabel(techName,
                    isHeader: false, textColor: Colors.white),
                _buildTableCellLabel("${distances.length}",
                    isHeader: false, isMono: true, textColor: Colors.white70),
                _buildTableCellLabel("${techAvg.toStringAsFixed(2)}m",
                    isHeader: false, isMono: true, textColor: Colors.white),
                _buildTableCellLabel(deltaStr,
                    isHeader: false, isMono: true, textColor: deltaColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableCellLabel(String content,
      {required bool isHeader, bool isMono = false, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: isHeader ? 9 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontFamily: isMono ? 'Courier' : null,
          color: textColor,
        ),
        textAlign: TextAlign.left,
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
    List techFilterOptions = [
      "All Techniques",
      ..._disciplineTechniques[discipline]!
    ];
    double windowMax = 0.0;
    double windowAvg = 0.0;
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
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListExpandedDelegate([
              TimeFilterRow(
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
                            child: Theme(
                              data: ThemeData.dark()
                                  .copyWith(canvasColor: Colors.transparent),
                              child: ChoiceChip(
                                label: Text(windowName,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white70)),
                                selected: isSelected,
                                selectedColor: dynamicAccent,
                                onSelected: (s) => setState(
                                    () => _activeTimeFilter = windowName),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: techFilterOptions.map((tName) {
                          bool isSelected = _activeTechniqueFilter == tName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Theme(
                              data: ThemeData.dark()
                                  .copyWith(canvasColor: Colors.transparent),
                              child: ChoiceChip(
                                label: Text(tName,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white60)),
                                selected: isSelected,
                                selectedColor: dynamicAccent.withOpacity(0.8),
                                onSelected: (s) => setState(
                                    () => _activeTechniqueFilter = tName),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text("${_activeTimeFilter.toUpperCase()} ANALYTICS MATRIX GRAPH",
                  style: TextStyle(
                      fontSize: 12,
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
                            "No records caught inside this date frame window.",
                            style: TextStyle(fontSize: 12, color: Colors.grey)))
                    : CustomPaint(
                        painter: TrainingLineChartPainter(
                            entries: filteredFeed,
                            targetMerit: meritStandard,
                            accentColor: dynamicAccent)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 10, height: 10, color: dynamicAccent),
                    const SizedBox(width: 6),
                    const Text("Logged Distance",
                        style: TextStyle(fontSize: 12, color: Colors.grey))
                  ]),
                  Row(children: [
                    Container(
                        width: 10, height: 2, color: const Color(0xFFFF5252)),
                    const SizedBox(width: 6),
                    Text(
                        "National Merit Threshold (${meritStandard.toStringAsFixed(2)}m)",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey))
                  ]),
                ],
              ),
              const SizedBox(height: 24),
              Text("MOVEMENT VARIANT DELTA METRICS",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: dynamicAccent,
                      letterSpacing: 1.2)),
              _buildTechniqueEfficiencyMatrixTable(discipline, dynamicAccent),
              const SizedBox(height: 10),
              Text("${_activeTimeFilter.toUpperCase()} CALCULATIONS GRID",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: dynamicAccent,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTimelineStatMiniCard("BEST THROW",
                          "${windowMax.toStringAsFixed(2)}m", dynamicAccent)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTimelineStatMiniCard(
                          "AVERAGE DISTANCE",
                          "${windowAvg.toStringAsFixed(2)}m",
                          const Color(0xFFEEE3D3))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTimelineStatMiniCard("TOTAL THROWS",
                          "${filteredFeed.length}", dynamicAccent)),
                ],
              )
            ]),
          ),
        )
      ],
    );
  }

  Widget _buildTimelineStatMiniCard(
      String label, String value, Color textAccent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1E221F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  color: textAccent)),
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
          _buildProfessionalManualCard(
              "1. CUSTOM WEIGHT ESTIMATION",
              "If you practice with a heavier or lighter implement than standard rules require, this app estimates how far your throw would go with a standard weight item.",
              "Easy Formula:\nProjected Distance = Logged Distance × (Override Weight / Standard Group Weight)",
              accent),
          _buildProfessionalManualCard(
              "2. NATIONAL QUALITY LINES",
              "The bright red target line running across your history charts highlights the official national standard for your age and gender division.",
              "Current Example Benchmark:\nFor instance, an active M55 Discus thrower tracks progress cleanly against an official target line pinned at 29.10m.",
              accent),
          _buildProfessionalManualCard(
              "3. TRACKING TECHNIQUE VARIANTS",
              "You can log your throws based on the specific movement pattern you used (like Standing Throws versus Full Rotations).",
              "Database Execution Layer:\nThis segregation lets you check whether your advanced techniques are effectively outperforming basic standing stability throws.",
              accent),
          _buildProfessionalManualCard(
              "4. SEPARATING TRAINING & COMPETITIONS",
              "The system separates your preparation sessions from official meets to prevent high-stress tournament results from getting mixed up with daily training meets.",
              "Workload Filtering Actions:\nToggle data views dynamically using the top filter buttons to isolate baseline preparation metrics from meet results instantly.",
              accent),
        ],
      ),
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
                  fontSize: 13,
                  fontFamily: 'Courier',
                  letterSpacing: 1)),
          const Divider(height: 16, color: Colors.white12),
          Text(summary,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFEEE3D3), height: 1.4)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            child: Text(details,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                    fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }

  Widget _buildFlatOnboardingView({required bool canCancel}) {
    return Scaffold(
      appBar: canCancel
          ? AppBar(
              title: const Text("ADD ATHLETE"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _isAddingNewUser = false),
              ),
            )
          : null,
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Male (M)",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
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
                              fontSize: 12, fontWeight: FontWeight.bold)),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_countriesList.length, (idx) {
                        bool isSel = _onboardingCountryIdx == idx;
                        return InkWell(
                          onTap: () =>
                              setState(() => _onboardingCountryIdx = idx),
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
                                    color:
                                        isSel ? Colors.black : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("AGE BAND DIVISION",
                    style: TextStyle(
                        fontSize: 11,
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () =>
                              setState(() => _isAddingNewUser = false),
                          child: const Text("CANCEL",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (canCancel) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFACBC9A),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () async {
                          if (_onboardingNameController.text
                              .trim()
                              .isNotEmpty) {
                            final db = DatabaseHelper.instance;
                            bool isCreated = await db.createProfile(
                                _onboardingNameController.text.trim(),
                                _onboardingSelectedSex,
                                _ageGroupsList[_onboardingAgeIdx],
                                country: _countriesList[_onboardingCountryIdx]);
                            if (isCreated) {
                              _onboardingNameController.clear();
                              _isAddingNewUser = false;
                              await _initializeAppDatabaseAndProfiles();
                            }
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
              ],
            ),
          ),
        ),
      ),
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
    if (entries.isEmpty) {
      return;
    }
    final paintLine = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paintDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final paintAxis = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.2;
    final paintMerit = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.0;
    final textPaint = TextPainter(textDirection: TextDirection.ltr);
    double maxDistance = targetMerit;
    double minDistance = targetMerit;
    for (var e in entries) {
      if (e.loggedDistance > maxDistance) {
        maxDistance = e.loggedDistance;
      }
      if (e.loggedDistance < minDistance) {
        minDistance = e.loggedDistance;
      }
    }
    maxDistance = math.max(maxDistance, targetMerit) * 1.15;
    minDistance = math.max(0.0, minDistance - 4.0);
    double range = maxDistance - minDistance;
    if (range <= 0) {
      range = 1.0;
    }
    int lineCount = 4;
    for (int i = 0; i <= lineCount; i++) {
      double factor = i / lineCount;
      double yPos = size.height - (factor * size.height);
      double val = minDistance + (factor * range);
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paintAxis);
      textPaint.text = TextSpan(
          text: "${val.toStringAsFixed(1)}m",
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold));
      textPaint.layout();
      textPaint.paint(canvas, Offset(-28, yPos - 5));
    }
    double meritY =
        size.height - (((targetMerit - minDistance) / range) * size.height);
    canvas.drawLine(Offset(0, meritY), Offset(size.width, meritY), paintMerit);
    textPaint.text = TextSpan(
        text: "MERIT TARGET: ${targetMerit.toStringAsFixed(2)}m",
        style: const TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 9,
            fontWeight: FontWeight.w900));
    textPaint.layout();
    textPaint.paint(canvas, Offset(4, meritY - 14));
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

class SliverChildListExpandedDelegate extends SliverChildDelegate {
  final List children;
  SliverChildListExpandedDelegate(this.children);
  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) {
      return null;
    }
    return children[index];
  }

  @override
  int get estimatedChildCount => children.length;
  @override
  bool shouldRebuild(covariant SliverChildListExpandedDelegate oldDelegate) =>
      true;
}

class TimeFilterRow extends StatelessWidget {
  final Widget child;
  const TimeFilterRow({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
