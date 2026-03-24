import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import '../timer_state.dart';

class LaunchScreen extends StatefulWidget {
  final TimerState timerState;

  const LaunchScreen({super.key, required this.timerState});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _restoreWindow();
    // Repopulate fields if tasks were set previously
    for (int i = 0; i < 4; i++) {
      _controllers[i].text = widget.timerState.tasks[i];
    }
  }

  Future<void> _restoreWindow() async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setMinimumSize(const Size(400, 680));
    await windowManager.setSize(const Size(400, 680));
    final screen = await screenRetriever.getPrimaryDisplay();
    final sw = screen.size.width;
    await windowManager.setPosition(Offset(sw - 400 - 8, 28));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    final tasks = _controllers.map((c) => c.text.trim()).toList();
    widget.timerState.start(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Image.asset(
              'images/mrt_large.png',
              height: 234,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: TextField(
                controller: _controllers[i],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Task ${i + 1} (optional)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "I PITY THE FOOL WHO DOESN'T START!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: widget.timerState,
              builder: (context, _) => Text(
                'Today: ${widget.timerState.todayCount}    All-time: ${widget.timerState.totalCount}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
