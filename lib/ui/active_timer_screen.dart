import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import '../timer_state.dart';

class ActiveTimerScreen extends StatefulWidget {
  final TimerState timerState;

  const ActiveTimerScreen({super.key, required this.timerState});

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  @override
  void initState() {
    super.initState();
    _shrinkWindow();
  }

  Future<void> _shrinkWindow() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setMinimumSize(const Size(200, 80));
    await windowManager.setSize(const Size(200, 80));
    await windowManager.setAlwaysOnTop(true);
    final screen = await screenRetriever.getPrimaryDisplay();
    final sw = screen.size.width;
    await windowManager.setPosition(Offset(sw - 200 - 8, 28));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.timerState,
        builder: (context, _) {
          final state = widget.timerState;
          final isLongBreak = state.phase == PomodoroPhase.longBreak;
          final isBreak = state.phase != PomodoroPhase.work;

          // Image: mr_pause only during long break; mrt_small otherwise
          final imagePath = isLongBreak
              ? 'images/mr_pause.png'
              : 'images/mrt_small.png';

          // Bottom strip text
          final String bottomText;
          if (state.phase == PomodoroPhase.shortBreak) {
            bottomText = 'TAKE A SMALL BREAK';
          } else if (isLongBreak) {
            bottomText = 'TAKE A LONG BREAK';
          } else {
            bottomText = state.activeTask;
          }

          return DragToMoveArea(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Left: Mr. T image
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          imagePath,
                          width: 52,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Right: timer + buttons
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.formattedTime,
                                  style: TextStyle(
                                    color: _phaseColor(state.phase),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _iconBtn(
                                  icon: state.isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  color: Colors.amber,
                                  onPressed: () => state.isPaused
                                      ? state.resume()
                                      : state.pause(),
                                ),
                                _iconBtn(
                                  icon: Icons.stop,
                                  color: Colors.redAccent,
                                  onPressed: state.stop,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom strip — always shown, centered
                if (bottomText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: isBreak
                        ? const Color(0xFF2A1A00)
                        : const Color(0xFF1A1A1A),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      bottomText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isBreak ? Colors.amber.shade300 : Colors.grey,
                        fontSize: 9,
                        fontWeight:
                            isBreak ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Color _phaseColor(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return Colors.amber;
      case PomodoroPhase.shortBreak:
        return Colors.greenAccent;
      case PomodoroPhase.longBreak:
        return Colors.lightBlueAccent;
    }
  }
}
