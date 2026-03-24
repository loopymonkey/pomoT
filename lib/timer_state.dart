import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class TimerState extends ChangeNotifier {
  static const int workSeconds = 25 * 60;
  static const int shortBreakSeconds = 5 * 60;
  static const int longBreakSeconds = 15 * 60;
  static const int cyclesBeforeLongBreak = 4;

  static const List<String> _startSounds = [
    'sounds/start/no-time.m4a',
    'sounds/start/keep-your-mind-on-your-job.m4a',
    'sounds/start/first-thing-you-do-gotta-promise-me-to-shut-up.m4a',
  ];

  static const List<String> _breakSounds = [
    'sounds/break/yeah.m4a',
    'sounds/break/right-on.m4a',
  ];

  static const List<String> _pauseSounds = [
    'sounds/pause/wait.m4a',
    'sounds/pause/you-lied-to-me.m4a',
    'sounds/pause/you-tricked-me-suck-up.m4a',
  ];

  static const String _doneSound = 'sounds/done/done.m4a';

  static const _soundChannel = MethodChannel('pomot/sound');

  final _random = Random();
  final List<String> tasks = List.filled(4, '');

  PomodoroPhase _phase = PomodoroPhase.work;
  int _cycleCount = 0;
  int _activeTaskIndex = 0;
  int _secondsRemaining = workSeconds;
  bool _isRunning = false;
  bool _isPaused = false;

  int _todayCount = 0;
  int _totalCount = 0;
  String _todayKey = '';

  Timer? _timer;

  PomodoroPhase get phase => _phase;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get todayCount => _todayCount;
  int get totalCount => _totalCount;

  String get formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get activeTask {
    final nonEmpty = tasks.where((t) => t.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return '';
    return nonEmpty[_activeTaskIndex % nonEmpty.length];
  }

  TimerState() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCount = prefs.getInt('total_count') ?? 0;
    final today = _dateKey();
    _todayKey = today;
    _todayCount = prefs.getInt('today_count_$today') ?? 0;
    notifyListeners();
  }

  String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    if (today != _todayKey) {
      _todayKey = today;
      _todayCount = 1;
    }
    await prefs.setInt('total_count', _totalCount);
    await prefs.setInt('today_count_$today', _todayCount);
  }

  void start(List<String> taskInputs) {
    for (int i = 0; i < tasks.length; i++) {
      tasks[i] = i < taskInputs.length ? taskInputs[i] : '';
    }
    _activeTaskIndex = 0;
    _phase = PomodoroPhase.work;
    _cycleCount = 0;
    _secondsRemaining = workSeconds;
    _isRunning = true;
    _isPaused = false;
    _startTick();
    notifyListeners();
    _playRandom(_startSounds);
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    notifyListeners();
    _playRandom(_pauseSounds);
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _startTick();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _phase = PomodoroPhase.work;
    _cycleCount = 0;
    _activeTaskIndex = 0;
    _secondsRemaining = workSeconds;
    notifyListeners();
    _playRandom(_pauseSounds);
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      _advancePhase();
    }
  }

  void _advancePhase() {
    _timer?.cancel();

    if (_phase == PomodoroPhase.work) {
      _cycleCount++;
      _todayCount++;
      _totalCount++;
      _savePrefs();

      final nonEmpty = tasks.where((t) => t.trim().isNotEmpty).toList();
      if (nonEmpty.length > 1) {
        _activeTaskIndex = (_activeTaskIndex + 1) % nonEmpty.length;
      }

      if (_cycleCount % cyclesBeforeLongBreak == 0) {
        _phase = PomodoroPhase.longBreak;
        _secondsRemaining = longBreakSeconds;
        _play(_doneSound);
      } else {
        _phase = PomodoroPhase.shortBreak;
        _secondsRemaining = shortBreakSeconds;
        _playRandom(_breakSounds);
      }
    } else {
      _phase = PomodoroPhase.work;
      _secondsRemaining = workSeconds;
      _playRandom(_startSounds);
    }

    _startTick();
    notifyListeners();
  }

  void _playRandom(List<String> sounds) {
    _play(sounds[_random.nextInt(sounds.length)]);
  }

  Future<void> _play(String assetPath) async {
    try {
      await _soundChannel.invokeMethod<void>('play', assetPath);
    } on PlatformException catch (e) {
      debugPrint('Audio error [$assetPath]: ${e.code} — ${e.message} (${e.details})');
    } catch (e) {
      debugPrint('Audio error [$assetPath]: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
