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

final List<String> _onboardingCountries = [
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
  'Guyana',
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

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedTab = 0;
  bool _isUserInitialized = false;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedCountry;
  String _selectedDiscipline = 'Shot Put';

  final Map<String, Color> _disciplineAccents = {
    'Shot Put': const Color(0xFFACBC9A),
    'Discus': const Color(0xFFBC9A9A),
    'Hammer': const Color(0xFF9ABABC),
    'Javelin': const Color(0xFFBCBA9A),
  };

  final Map<String, Color> _disciplineBackgrounds = {
    'Shot Put': const Color(0xFF1E221F),
    'Discus': const Color(0xFF221E1E),
    'Hammer': const Color(0xFF1E2222),
    'Javelin': const Color(0xFF22221E),
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
          _selectedDiscipline = user['discipline'] ?? 'Shot Put';
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
    final logs =
        await DatabaseHelper.instance.getThrowLogs(_selectedDiscipline);
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
      _selectedDiscipline,
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
        if (_selectedDiscipline == 'Shot Put') {
          selectedVariant = 'Glide';
        }
        if (_selectedDiscipline == 'Javelin') {
          selectedVariant = '5-Step Approach';
        }

        final List<String> variants = _selectedDiscipline == 'Shot Put'
            ? ['Standing Throw', 'Glide', 'Rotation']
            : _selectedDiscipline == 'Discus' || _selectedDiscipline == 'Hammer'
                ? ['Standing Throw', 'Half Turn', 'Full Rotation']
                : ['Standing Throw', 'Short Approach', '5-Step Approach'];

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
                      backgroundColor: _disciplineAccents[_selectedDiscipline]),
                  onPressed: () async {
                    await DatabaseHelper.instance.insertThrowLog(
                      _selectedDiscipline,
                      selectedVariant,
                      dist,
                      DateTime.now().toIso8601String(),
                    );
                    _distanceController.clear();
                    if (!dialogContext.mounted) {
                      return;
                    }
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
    final Map<String, List> groupedDistances = {};
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
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Count',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Avg (m)',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Eff Delta',
                    style: TextStyle(fontWeight: FontWeight.bold))),
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
                  padding: const EdgeInsets.all(8.0), child: Text(entry.key)),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${entry.value.length}')),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(avg.toStringAsFixed(2))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  deltaText,
                  style:
                      TextStyle(color: deltaColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }),
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
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _selectedDiscipline,
                  dropdownColor: const Color(0xFF1E221F),
                  decoration: InputDecoration(
                    labelText: 'Primary Discipline Focus',
                    prefixIcon:
                        const Icon(Icons.star, color: Color(0xFFACBC9A)),
                    filled: true,
                    fillColor: const Color(0xFF1E221F),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: ['Shot Put', 'Discus', 'Hammer', 'Javelin']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedDiscipline = val!),
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
    final Color currentAccent = _disciplineAccents[_selectedDiscipline]!;
    final Color currentCardBg = _disciplineBackgrounds[_selectedDiscipline]!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Throws Hub: $_selectedDiscipline',
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () async => await _loadThrowLogs(),
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Shot Put', 'Discus', 'Hammer', 'Javelin']
                        .map((discipline) {
                      final bool isSelected = _selectedDiscipline == discipline;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(discipline),
                          selected: isSelected,
                          selectedColor: _disciplineAccents[discipline],
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF131614)
                                  : const Color(0xFFEEE3D3)),
                          backgroundColor: const Color(0xFF1E221F),
                          onSelected: (selected) async {
                            if (selected) {
                              setState(() {
                                _selectedDiscipline = discipline;
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Measured Metric Distance (m)',
                              labelStyle: TextStyle(
                                  color: currentAccent.withOpacity(0.8)),
                              border: const UnderlineInputBorder(),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: currentAccent)),
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_throwHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                        'No historical parameters mapped across this discipline execution track.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38)),
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
                        key: Key('throw_entry_$id'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await DatabaseHelper.instance.deleteThrowLog(id);
                          setState(() {
                            _throwHistory.removeAt(index);
                          });
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Log element purged successfully.')),
                          );
                        },
                        child: Card(
                          color: const Color(0xFF1E221F),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: currentAccent.withOpacity(0.1),
                              child:
                                  Icon(Icons.analytics, color: currentAccent),
                            ),
                            title: Text("${item['distance']} meters",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text(
                                "${item['techniqueVariant']} • ${item['dateStamp'].toString().split('T')}"),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('TECHNIQUE EFFICIENCY MATRIX',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Calculates real performance improvement vectors relative to your basic Standing Throw tracking baseline.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                if (_throwHistory.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                              'Log performance parameters to construct efficiency grid structures.',
                              style: TextStyle(color: Colors.white38))))
                else
                  _buildTechniqueEfficiencyMatrixTable(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        backgroundColor: const Color(0xFF1E221F),
        selectedItemColor: currentAccent,
        unselectedItemColor: Colors.white38,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.history_edu), label: 'Logs Matrix'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: 'Analytics Grid'),
        ],
      ),
    );
  }
}
