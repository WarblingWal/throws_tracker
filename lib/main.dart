import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
        scaffoldBackgroundColor: const Color(0xFF131516),
        primaryColor: const Color(0xFFACBC9A),
        cardColor: const Color(0xFF1E2022),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class ThrowEntry {
  final double loggedDistance;
  final double activeWeight;
  final double projectedDistance;

  const ThrowEntry({
    required this.loggedDistance,
    required this.activeWeight,
    required this.projectedDistance,
  });
}

class HistoricSessionData {
  final double personalBest;
  final double weeklyAvg;
  final double monthlyAvg;
  final double yearlyAvg;

  const HistoricSessionData({
    required this.personalBest,
    required this.weeklyAvg,
    required this.monthlyAvg,
    required this.yearlyAvg,
  });
}

class UserProfile {
  final int id;
  final String username;
  final String sex;
  final String ageGroup;

  UserProfile({
    required this.id,
    required this.username,
    required this.sex,
    required this.ageGroup,
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
  final Map<String, int> _expandedAccordionIndex = {
    'Discus': -1,
    'Shot Put': -1,
    'Javelin': -1,
    'Hammer': -1,
    'Weight': -1
  };

  final TextEditingController _distanceFieldController =
      TextEditingController();
  final TextEditingController _onboardingNameController =
      TextEditingController();

  final Map<String, HistoricSessionData> _historicalData = {
    'Discus': const HistoricSessionData(
        personalBest: 54.20,
        weeklyAvg: 50.45,
        monthlyAvg: 49.80,
        yearlyAvg: 48.90),
    'Shot Put': const HistoricSessionData(
        personalBest: 18.40,
        weeklyAvg: 16.95,
        monthlyAvg: 16.50,
        yearlyAvg: 15.80),
    'Javelin': const HistoricSessionData(
        personalBest: 68.50,
        weeklyAvg: 63.80,
        monthlyAvg: 62.10,
        yearlyAvg: 60.40),
    'Hammer': const HistoricSessionData(
        personalBest: 61.30,
        weeklyAvg: 57.40,
        monthlyAvg: 56.20,
        yearlyAvg: 54.10),
    'Weight': const HistoricSessionData(
        personalBest: 21.10,
        weeklyAvg: 19.40,
        monthlyAvg: 18.90,
        yearlyAvg: 18.10),
  };

  late stt.SpeechToText _speechEngine;
  bool _isVoiceListening = false;
  String _voiceWordsTranscribed =
      "Press Microphone to activate voice parsing commands";

  @override
  void initState() {
    super.initState();
    _speechEngine = stt.SpeechToText();
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
      _loadSavedUserThrows();
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
                loggedDistance: m['loggedDistance'] as double,
                activeWeight: m['activeWeight'] as double,
                projectedDistance: m['projectedDistance'] as double,
              ))
          .toList();

      setState(() {
        _sessionLogs[discipline] = entries;
      });
    }
  }

  double _getStandardWeight(String discipline, String division) {
    bool isMale = division.startsWith('M');
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
    } else if (division.contains('60') ||
        division.contains('65') ||
        division.contains('70') ||
        division.contains('75') ||
        division.contains('80') ||
        division.contains('85') ||
        division.contains('90')) {
      if (discipline == 'Discus') {
        return isMale ? 1.0 : 0.75;
      }
      if (discipline == 'Shot Put') {
        return isMale ? 5.0 : 2.0;
      }
      if (discipline == 'Javelin') {
        return isMale ? 600.0 : 400.0;
      }
      if (discipline == 'Hammer') {
        return isMale ? 5.0 : 2.0;
      }
      return isMale ? 9.08 : 5.45;
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

  double _calculateProjectedDistance(
      double distance, double actualW, double standardW) {
    if (actualW == standardW || actualW <= 0) {
      return distance;
    }
    return distance * (actualW / standardW);
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

  void _parseVoiceCommand(String rawSentence) async {
    String phrase = rawSentence.toLowerCase();
    if (!phrase.contains('enter') && !phrase.contains('throw')) {
      return;
    }

    UserProfile? matchedUser;
    for (var profile in _allProfiles) {
      if (phrase.contains(profile.username.toLowerCase())) {
        matchedUser = profile;
        break;
      }
    }
    matchedUser ??= _currentActiveUser;
    if (matchedUser == null) {
      return;
    }

    String? matchedDiscipline;
    if (phrase.contains('discus')) {
      matchedDiscipline = 'Discus';
    } else if (phrase.contains('shot') || phrase.contains('put')) {
      matchedDiscipline = 'Shot Put';
    } else if (phrase.contains('javelin')) {
      matchedDiscipline = 'Javelin';
    } else if (phrase.contains('hammer')) {
      matchedDiscipline = 'Hammer';
    } else if (phrase.contains('weight')) {
      matchedDiscipline = 'Weight';
    }
    matchedDiscipline ??=
        _activeMenuIndex > 0 ? _disciplines[_activeMenuIndex - 1] : 'Discus';

    double meters = 0.0;
    double centimeters = 0.0;
    RegExp meterRegex = RegExp(r'(\d+)\s*meter');
    RegExp cmRegex = RegExp(r'(\d+)\s*centimeter');

    var meterMatch = meterRegex.firstMatch(phrase);
    if (meterMatch != null) {
      meters = double.tryParse(meterMatch.group(1) ?? '0') ?? 0.0;
    }
    var cmMatch = cmRegex.firstMatch(phrase);
    if (cmMatch != null) {
      centimeters = double.tryParse(cmMatch.group(1) ?? '0') ?? 0.0;
    }

    double finalDistance = meters + (centimeters / 100.0);
    if (finalDistance <= 0.0) {
      return;
    }

    String targetDiv = "${matchedUser.sex}${matchedUser.ageGroup}";
    double standardW = _getStandardWeight(matchedDiscipline, targetDiv);
    double processingW = _customWeightOverrides[matchedDiscipline] ?? standardW;
    double projectedDist =
        _calculateProjectedDistance(finalDistance, processingW, standardW);

    await DatabaseHelper.instance.insertThrow(
      userId: matchedUser.id,
      discipline: matchedDiscipline,
      division: targetDiv,
      loggedDistance: finalDistance,
      activeWeight: processingW,
      projectedDistance: projectedDist,
    );

    if (_currentActiveUser != null &&
        matchedUser.id == _currentActiveUser!.id) {
      _loadSavedUserThrows();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFACBC9A),
        content: Text(
            "Voice Logged for ${matchedUser.username}: $matchedDiscipline -> ${finalDistance.toStringAsFixed(2)}m",
            style: const TextStyle(
                color: Color(0xFF131516), fontWeight: FontWeight.bold)),
      ));
    }
  }

  void _toggleVoiceListening() async {
    if (!_isVoiceListening) {
      bool available = await _speechEngine.initialize(
        onStatus: (status) => debugPrint('Speech Status: $status'),
        onError: (errorNotification) =>
            debugPrint('Speech Error: $errorNotification'),
      );
      if (available) {
        setState(() => _isVoiceListening = true);
        _speechEngine.listen(onResult: (result) {
          setState(() {
            _voiceWordsTranscribed = result.recognizedWords;
            if (result.finalResult) {
              _parseVoiceCommand(result.recognizedWords);
              _isVoiceListening = false;
            }
          });
        });
      }
    } else {
      setState(() => _isVoiceListening = false);
      _speechEngine.stop();
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Throws Hub Pro: ${_currentActiveUser!.username} ($_selectedDivision)',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier')),
        backgroundColor: const Color(0xFF1E2022),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Color(0xFFACBC9A)),
            onPressed: () async {
              await DatabaseHelper.instance.clearActiveProfile();
              _initializeAppDatabaseAndProfiles();
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeMenuIndex,
        selectedItemColor: const Color(0xFFACBC9A),
        unselectedItemColor: const Color(0xFF6C7075),
        backgroundColor: const Color(0xFF1E2022),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _activeMenuIndex = index),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Overview'),
          ..._disciplines.map((d) => BottomNavigationBarItem(
              icon: Icon(_getDisciplineIcon(d)), label: d)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            _isVoiceListening ? Colors.redAccent : const Color(0xFFACBC9A),
        onPressed: _toggleVoiceListening,
        child: Icon(_isVoiceListening ? Icons.mic : Icons.mic_none,
            color: const Color(0xFF131516)),
      ),
      body: Column(
        children: [
          if (_isVoiceListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E2022),
              child: Text(_voiceWordsTranscribed,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFACBC9A),
                      fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          Expanded(
            child: _activeMenuIndex == 0
                ? _buildDashboardMatrixOverview()
                : _buildDisciplineLayout(_disciplines[_activeMenuIndex - 1]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMatrixOverview() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _disciplines.length,
      itemBuilder: (context, idx) {
        final d = _disciplines[idx];
        final throws = _sessionLogs[d] ?? [];
        return GestureDetector(
          onTap: () => setState(() => _activeMenuIndex = idx + 1),
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(14),
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
                            fontSize: 13,
                            letterSpacing: 1)),
                    Icon(_getDisciplineIcon(d),
                        color: const Color(0xFFACBC9A), size: 18),
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
                            fontSize: 22,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text("Total Attempts: ${throws.length}",
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisciplineLayout(String discipline) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF131516),
            child: const TabBar(
              indicatorColor: Color(0xFFACBC9A),
              indicatorWeight: 2,
              labelColor: Color(0xFFACBC9A),
              unselectedLabelColor: Color(0xFF6C7075),
              tabs: [
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
                _buildCurrentSessionView(discipline),
                _buildHistoricalView(discipline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionView(String discipline) {
    final feed = _sessionLogs[discipline]!;
    final stats = _historicalData[discipline]!;
    double standardW = _getStandardWeight(discipline, _selectedDivision);
    double processingW = _customWeightOverrides[discipline] ?? standardW;
    double sessionAvg = feed.isEmpty
        ? 0.0
        : feed.map((e) => e.loggedDistance).reduce((a, b) => a + b) /
            feed.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                    child: _buildPanelStatNode(
                        "AGE SPEC PB",
                        "${stats.personalBest.toStringAsFixed(2)}m",
                        const Color(0xFFACBC9A))),
                Container(width: 1, height: 40, color: const Color(0xFF3E4246)),
                Expanded(
                    child: _buildPanelStatNode(
                        "SESSION AVG",
                        "${sessionAvg.toStringAsFixed(2)}m",
                        const Color(0xFFEEE3D3))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF383C41))),
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("IMPLEMENT WEIGHT CAPTURE",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF909499))),
                    const SizedBox(height: 2),
                    Text(
                        _customWeightOverrides[discipline] == null
                            ? "Division Standard"
                            : "Custom Override Running",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFACBC9A))),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        double current =
                            _customWeightOverrides[discipline] ?? standardW;
                        _customWeightOverrides[discipline] =
                            (current - (discipline == 'Javelin' ? 50 : 0.25))
                                .clamp(0.1, 1000.0);
                      }),
                    ),
                    Text(
                        "${processingW.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                        style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() {
                        double current =
                            _customWeightOverrides[discipline] ?? standardW;
                        _customWeightOverrides[discipline] =
                            current + (discipline == 'Javelin' ? 50 : 0.25);
                      }),
                    ),
                    if (_customWeightOverrides[discipline] != null)
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.redAccent, size: 18),
                        onPressed: () => setState(
                            () => _customWeightOverrides[discipline] = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _distanceFieldController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
                  decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF131516),
                      labelText: 'Distance (meters)',
                      labelStyle: TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
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
                        _loadSavedUserThrows();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFACBC9A)),
                    child: const Text("SAVE ENTRY",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131516))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildThrowLogList(feed, discipline),
        ],
      ),
    );
  }

  Widget _buildThrowLogList(List<ThrowEntry> feed, String discipline) {
    if (feed.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
          color: const Color(0xFF1E2022),
          borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: feed.length,
        itemBuilder: (c, index) {
          final item = feed[feed.length - 1 - index];
          bool hasVariance = item.loggedDistance != item.projectedDistance;
          return ListTile(
            title: Text("Attempt #${feed.length - index}",
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Weight: ${item.activeWeight.toStringAsFixed(1)}${discipline == 'Javelin' ? 'g' : 'kg'}",
                style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${item.loggedDistance.toStringAsFixed(2)}m",
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                if (hasVariance)
                  Text("Std: ${item.projectedDistance.toStringAsFixed(2)}m",
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFACBC9A))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoricalView(String discipline) {
    final data = _historicalData[discipline]!;
    List<Map<String, dynamic>> recordsList = [
      {"title": "Weekly Rolling Average", "val": data.weeklyAvg},
      {"title": "Monthly Rolling Average", "val": data.monthlyAvg},
      {"title": "Yearly Rolling Average", "val": data.yearlyAvg},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recordsList.length,
      itemBuilder: (context, index) {
        bool isExpanded = _expandedAccordionIndex[discipline] == index;
        final row = recordsList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: const Color(0xFF1E2022),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              ListTile(
                title: Text(row["title"] as String,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFEEE3D3))),
                trailing: Text("${(row["val"] as double).toStringAsFixed(2)}m",
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFACBC9A))),
                onTap: () => setState(() {
                  _expandedAccordionIndex[discipline] = isExpanded ? -1 : index;
                }),
              ),
              if (isExpanded) _buildAccordionGraphContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccordionGraphContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF17191B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HISTORICAL SCALING SNAPSHOT GRAPH",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (barIndex) {
              double heightFactor = [0.6, 0.75, 0.82, 0.9, 0.95][barIndex];
              return Column(
                children: [
                  Container(
                    height: 70 * heightFactor,
                    width: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFACBC9A)
                          .withOpacity(0.4 + (barIndex * 0.12)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("T-${5 - barIndex}",
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    String selectedSex = "M";
    String selectedAge = "55";
    List<String> ages = [
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
                color: const Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CREATE ATHLETE PROFILE",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEEE3D3),
                        fontFamily: 'Courier')),
                const SizedBox(height: 6),
                const Text("Setup multiple training accounts cleanly below.",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: _onboardingNameController,
                  style: const TextStyle(fontFamily: 'Courier'),
                  decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF131516),
                      labelText: "Username / Name",
                      labelStyle: TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 16),
                const Text("BIOLOGICAL SEX",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 6),
                StatefulBuilder(
                  builder: (context, setSubState) {
                    return Row(
                      children: ["M", "W"].map((s) {
                        bool active = selectedSex == s;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSubState(() => selectedSex = s),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFACBC9A)
                                      : const Color(0xFF131516),
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(s == "M" ? "Male" : "Female",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: active
                                          ? const Color(0xFF131516)
                                          : Colors.white)),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text("AGE MASTER MATRIX GROUP",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 6),
                StatefulBuilder(
                  builder: (context, setSubState) {
                    return Column(
                      children: [
                        DropdownButton<String>(
                          value: selectedAge,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF131516),
                          style: const TextStyle(
                              color: Color(0xFFACBC9A),
                              fontWeight: FontWeight.bold),
                          items: ages
                              .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a == 'Sch'
                                      ? "School Bracket"
                                      : a == 'Sen'
                                          ? "Senior Bracket"
                                          : "Masters $a+")))
                              .toList(),
                          onChanged: (v) => setSubState(() => selectedAge = v!),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFACBC9A)),
                            onPressed: () async {
                              if (_onboardingNameController.text
                                  .trim()
                                  .isNotEmpty) {
                                final db = DatabaseHelper.instance;
                                int id = await db.createProfile(
                                    _onboardingNameController.text.trim(),
                                    selectedSex,
                                    selectedAge);
                                await db.setActiveProfile(id);
                                _onboardingNameController.clear();
                                _initializeAppDatabaseAndProfiles();
                              }
                            },
                            child: const Text("INITIALIZE ACCOUNT",
                                style: TextStyle(
                                    color: Color(0xFF131516),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  },
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
                fontSize: 10,
                color: Color(0xFF909499),
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontFamily: 'Courier',
                color: textAccent)),
      ],
    );
  }
}
