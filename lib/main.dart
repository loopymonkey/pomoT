import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'timer_state.dart';
import 'ui/launch_screen.dart';
import 'ui/active_timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(400, 680),
    minimumSize: Size(400, 680),
    center: true,
    title: 'Pomo-T',
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const PomoTApp());
}

class PomoTApp extends StatefulWidget {
  const PomoTApp({super.key});

  @override
  State<PomoTApp> createState() => _PomoTAppState();
}

class _PomoTAppState extends State<PomoTApp> {
  late final TimerState _timerState;

  @override
  void initState() {
    super.initState();
    _timerState = TimerState();
  }

  @override
  void dispose() {
    _timerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pomo-T',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
      ),
      home: ListenableBuilder(
        listenable: _timerState,
        builder: (context, _) {
          if (_timerState.isRunning) {
            return ActiveTimerScreen(timerState: _timerState);
          }
          return LaunchScreen(timerState: _timerState);
        },
      ),
    );
  }
}
