import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Zen',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F7F3),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18, color: Color(0xFF444444)),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFB6C197), // verde oliva suave
          secondary: const Color(0xFFDCE2C8),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB6C197),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            textStyle: const TextStyle(fontSize: 20),
          ),
          child: const Text('Entrar no foco'),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  int _remainingSeconds = 1500;
  bool _isRunning = false;
  int _customMinutes = 25;

  @override
  void initState() {
    super.initState();
    _loadCustomTime();
  }

  Future<void> _loadCustomTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customMinutes = prefs.getInt('customMinutes') ?? 25;
      _remainingSeconds = _customMinutes * 60;
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _saveFocusSession(_customMinutes);
        setState(() => _isRunning = false);
      }
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _customMinutes * 60;
      _isRunning = false;
    });
  }

  Future<void> _saveFocusSession(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = prefs.getInt(today) ?? 0;
    await prefs.setInt(today, total + minutes);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        1 - (_remainingSeconds / (_customMinutes * 60));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Zen'),
        backgroundColor: const Color(0xFFF9F7F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined, color: Color(0xFF444444)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF444444)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _loadCustomTime();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFE8E6E1),
                    color: const Color(0xFFB6C197),
                  ),
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF444444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: Icon(
                    _isRunning ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: const Color(0xFFB6C197),
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.refresh, color: Color(0xFFB6C197)),
                  onPressed: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentValue();
  }

  Future<void> _loadCurrentValue() async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = (prefs.getInt('customMinutes') ?? 25).toString();
  }

  Future<void> _saveCustomTime() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = int.tryParse(_controller.text) ?? 25;
    await prefs.setInt('customMinutes', minutes);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: const Color(0xFFF9F7F3),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração (minutos)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6C197),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: _saveCustomTime,
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, int> _focusData = {};

  @override
  void initState() {
    super.initState();
    _loadFocusData();
  }

  Future<void> _loadFocusData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = <String, int>{};
    for (final k in keys) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)) {
        data[k] = prefs.getInt(k) ?? 0;
      }
    }
    setState(() => _focusData = data);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _focusData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // mais recente primeiro

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        backgroundColor: const Color(0xFFF9F7F3),
        elevation: 0,
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('Nenhum registro ainda.\nComece seu foco hoje.',
                  textAlign: TextAlign.center),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final date = DateFormat('dd/MM/yyyy')
                    .format(DateTime.parse(entries[i].key));
                final minutes = entries[i].value;
                return ListTile(
                  title: Text(date,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text('$minutes min'),
                );
              },
            ),
    );
  }
}
