import 'package:flutter/material.dart';

void main() => runApp(const ThrowsTrackerApp());

class ThrowsTrackerApp extends StatelessWidget {
  const ThrowsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Throws Hub Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF131516), // Deep Slate
        primaryColor:
            const Color(0xFFACBC9A), // High-Contrast Muted Pastel Green
        cardColor: const Color(0xFF1E2022), // Premium Gunmetal Charcoal
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

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _activeMenuIndex = 0; // 0 = Home, 1 = Discus, 2 = Shot, etc.
  String _selectedDivision = "M55"; // World Athletics 5-year step matrix

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

  double _getStandardWeight(String discipline, String division) {
    bool isMale = division.startsWith('M');
    if (division.contains('55') || division.contains('50')) {
      if (discipline == 'Discus') return isMale ? 1.5 : 1.0;
      if (discipline == 'Shot Put') return isMale ? 6.0 : 3.0;
      if (discipline == 'Javelin') return isMale ? 700.0 : 500.0;
      if (discipline == 'Hammer') return isMale ? 6.0 : 3.0;
      return isMale ? 11.34 : 7.26;
    } else if (division.contains('60') ||
        division.contains('65') ||
        division.contains('70') ||
        division.contains('75') ||
        division.contains('80') ||
        division.contains('85') ||
        division.contains('90')) {
      if (discipline == 'Discus') return isMale ? 1.0 : 0.75;
      if (discipline == 'Shot Put') return isMale ? 5.0 : 2.0;
      if (discipline == 'Javelin') return isMale ? 600.0 : 400.0;
      if (discipline == 'Hammer') return isMale ? 5.0 : 2.0;
      return isMale ? 9.08 : 5.45;
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
    return distance *
        (actualW / standardW); // Parabolic physical correction factor
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
    List<String> divisionsList = [];
    for (var prefix in ['M', 'W']) {
      divisionsList.addAll([
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
      ].map((e) => e == 'Sch' || e == 'Sen' ? '$prefix$e' : '$prefix$e'));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text('THROWS HUB ',
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 18,
                                  color: Color(0xFFEEE3D3))),
                          Text('PRO',
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Color(0xFFACBC9A))),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedDivision,
                        dropdownColor: const Color(0xFF1E2022),
                        underline: const SizedBox(),
                        style: const TextStyle(
                            color: Color(0xFFACBC9A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        items: divisionsList
                            .map((div) =>
                                DropdownMenuItem(value: div, child: Text(div)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDivision = val!),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                      height: 1,
                      color: const Color(0xFFACBC9A).withOpacity(0.25)),
                ],
              ),
            ),
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTopMenuButton("Home", 0),
                  ...List.generate(
                      _disciplines.length,
                      (index) =>
                          _buildTopMenuButton(_disciplines[index], index + 1))
                ],
              ),
            ),
            const Divider(color: Color(0xFF25272B), height: 1),
            Expanded(
              child: _activeMenuIndex == 0
                  ? _buildHomeScreenLayout()
                  : _buildDisciplineLayout(_disciplines[_activeMenuIndex - 1]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenuButton(String title, int index) {
    bool isSelected = _activeMenuIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeMenuIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2B2E32) : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.center,
        child: Text(title,
            style: TextStyle(
                color: isSelected
                    ? const Color(0xFFACBC9A)
                    : const Color(0xFF9EA2A8),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildHomeScreenLayout() {
    String mostTrained = "Discus";
    int maxThrows = -1;
    _sessionLogs.forEach((key, list) {
      if (list.length > maxThrows) {
        maxThrows = list.length;
        mostTrained = key;
      }
    });

    List<String> subGridList = List.from(_disciplines)..remove(mostTrained);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DOMINANT TRAINING SNAPSHOT",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA2A6AB),
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildCapsuleCard(mostTrained, isFullWidth: true),
          const SizedBox(height: 20),
          const Text("EVENT TRACKING MATRIX GRID",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA2A6AB),
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: subGridList
                .map((discipline) =>
                    _buildCapsuleCard(discipline, isFullWidth: false))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleCard(String name, {required bool isFullWidth}) {
    final data = _historicalData[name]!;
    final log = _sessionLogs[name]!;
    double currentAvg = log.isEmpty
        ? 0.0
        : log.map((e) => e.loggedDistance).reduce((a, b) => a + b) / log.length;
    double currentWeight = _customWeightOverrides[name] ??
        _getStandardWeight(name, _selectedDivision);
    String weightLabel =
        "${currentWeight.toStringAsFixed(1)}${name == 'Javelin' ? 'g' : 'kg'}";

    return GestureDetector(
      onTap: () =>
          setState(() => _activeMenuIndex = _disciplines.indexOf(name) + 1),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2022),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFACBC9A)
                  .withOpacity(isFullWidth ? 0.35 : 0.15),
              width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        padding: EdgeInsets.all(isFullWidth ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getDisciplineIcon(name),
                        size: isFullWidth ? 20 : 16,
                        color: const Color(0xFFACBC9A)),
                    const SizedBox(width: 8),
                    Text(name,
                        style: TextStyle(
                            fontSize: isFullWidth ? 16 : 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEEE3D3))),
                  ],
                ),
                if (isFullWidth)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFACBC9A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text("TOP FOCUS",
                        style: TextStyle(
                            color: Color(0xFFACBC9A),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            SizedBox(height: isFullWidth ? 16 : 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Session Avg ($weightLabel)",
                        style: TextStyle(
                            fontSize: isFullWidth ? 11 : 9,
                            color: const Color(0xFFA2A6AB))),
                    const SizedBox(height: 2),
                    Text("${currentAvg.toStringAsFixed(2)}m",
                        style: TextStyle(
                            fontSize: isFullWidth ? 20 : 15,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("PERSONAL BEST",
                        style: TextStyle(
                            fontSize: isFullWidth ? 10 : 8,
                            color: const Color(0xFFACBC9A),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("${data.personalBest.toStringAsFixed(2)}m",
                        style: TextStyle(
                            fontSize: isFullWidth ? 20 : 15,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFACBC9A))),
                  ],
                )
              ],
            )
          ],
        ),
      ),
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
              child: TabBarView(children: [
            _buildCurrentSessionView(discipline),
            _buildHistoricalView(discipline)
          ])),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionView(String discipline) {
    final TextEditingController distanceFieldController =
        TextEditingController();
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
                                  _customWeightOverrides[discipline] ??
                                      standardW;
                              _customWeightOverrides[discipline] = (current -
                                      (discipline == 'Javelin' ? 50 : 0.25))
                                  .clamp(0.1, 1000.0);
                            })),
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
                                  _customWeightOverrides[discipline] ??
                                      standardW;
                              _customWeightOverrides[discipline] = current +
                                  (discipline == 'Javelin' ? 50 : 0.25);
                            })),
                    if (_customWeightOverrides[discipline] != null)
                      IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.redAccent, size: 18),
                          onPressed: () => setState(
                              () => _customWeightOverrides[discipline] = null))
                  ],
                )
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
                  controller: distanceFieldController,
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
                    onPressed: () {
                      double loggedDist =
                          double.tryParse(distanceFieldController.text) ?? 0.0;
                      if (loggedDist > 0.0) {
                        setState(() {
                          feed.insert(
                              0,
                              ThrowEntry(
                                  loggedDistance: loggedDist,
                                  activeWeight: processingW,
                                  projectedDistance:
                                      _calculateProjectedDistance(
                                          loggedDist, processingW, standardW)));
                        });
                        distanceFieldController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFACBC9A)),
                    child: const Text("SAVE ENTRY",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131516))),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (feed.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E2022),
                  borderRadius: BorderRadius.circular(8)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: feed.length,
                itemBuilder: (c, index) {
                  final item = feed[index];
                  bool hasVariance =
                      item.loggedDistance != item.projectedDistance;
                  return ListTile(
                    title: Text("Attempt #${feed.length - index}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
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
                          Text(
                              "Std: ${item.projectedDistance.toStringAsFixed(2)}m",
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFACBC9A))),
                      ],
                    ),
                  );
                },
              ),
            )
          ]
        ],
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
                title: Text(row["title"],
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFEEE3D3))),
                trailing: Text("${row["val"].toStringAsFixed(2)}m",
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFACBC9A))),
                onTap: () => setState(() {
                  _expandedAccordionIndex[discipline] = isExpanded ? -1 : index;
                }),
              ),
              if (isExpanded)
                Container(
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
                          double heightFactor =
                              [0.6, 0.75, 0.82, 0.9, 0.95][barIndex];
                          return Column(
                            children: [
                              Container(
                                  height: 70 * heightFactor,
                                  width: 24,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFACBC9A)
                                          .withOpacity(0.4 + (barIndex * 0.12)),
                                      borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Text("T-${5 - barIndex}",
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey)),
                            ],
                          );
                        }),
                      )
                    ],
                  ),
                )
            ],
          ),
        );
      },
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
