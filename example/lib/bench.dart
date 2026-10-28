// The frame bench: scripted drags over the example's sheets, with every frame's build and raster time per phase.
//
//   flutter run --profile -t lib/bench.dart -d <phone>
//
// It prints one `BENCH` line per phase. A late frame is one over the display's budget (8.3 ms at 120 Hz). Round 0
// pays first-use costs; read rounds 1 and 2.
import 'dart:async';
import 'dart:developer' show Timeline;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';

void main() {
  runApp(
    MaterialApp(
      navigatorKey: _navigator,
      home: const Scaffold(body: Center(child: Text('Bench'))),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
}

final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
final Stopwatch _clock = Stopwatch()..start();
int _pointer = 1;

/// A finger at 120 Hz: down at [from], moved by [dy] over [ms], then lifted.
Future<void> _drag(Offset from, double dy, {int ms = 220}) async {
  final int p = ++_pointer;
  final GestureBinding g = GestureBinding.instance;
  g.handlePointerEvent(PointerDownEvent(pointer: p, position: from, timeStamp: _clock.elapsed));
  final int steps = (ms / 8).ceil();
  for (int i = 1; i <= steps; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 8));
    g.handlePointerEvent(
      PointerMoveEvent(
        pointer: p,
        position: from + Offset(0, dy * i / steps),
        delta: Offset(0, dy / steps),
        timeStamp: _clock.elapsed,
      ),
    );
  }
  g.handlePointerEvent(PointerUpEvent(pointer: p, position: from + Offset(0, dy), timeStamp: _clock.elapsed));
}

Widget _sheet() => OnaBottomSheet(
  child: OnaSheetScaffold(
    header: const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: 7),
        OnaSheetGrabber(),
        SizedBox(height: 48, child: Center(child: Text('Templates'))),
      ],
    ),
    body: ListView.builder(
      dragStartBehavior: DragStartBehavior.down,
      itemCount: 40,
      itemBuilder: (BuildContext context, int i) =>
          ListTile(title: Text('Template ${i + 1}'), subtitle: const Text('Decisions, owners and dates')),
    ),
  ),
);

Future<void> _run() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  final FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  final Size screen = view.physicalSize / view.devicePixelRatio;
  final double x = screen.width / 2, h = screen.height;
  final List<FrameTiming> timings = <FrameTiming>[];
  final List<(String, int, int)> phases = <(String, int, int)>[];
  Future<void> phase(String name, Future<void> Function() run) async {
    final int from = Timeline.now;
    await run();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    phases.add((name, from, Timeline.now));
  }

  SchedulerBinding.instance.addTimingsCallback(timings.addAll);
  for (int round = 0; round < 3; round++) {
    await phase('r$round open', () async {
      unawaited(showOnaBottomSheet<void>(context: _navigator.currentContext!, builder: (_) => _sheet()));
    });
    await phase('r$round half>full', () => _drag(Offset(x, h / 2 + 24), -h * 0.42));
    await phase('r$round scroll', () => _drag(Offset(x, h * 0.7), -h * 0.35, ms: 120));
    await phase('r$round full>half', () => _drag(Offset(x, h * 0.12), h * 0.38));
    await phase('r$round close', () => _drag(Offset(x, h / 2 + 24), h * 0.45));
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  SchedulerBinding.instance.removeTimingsCallback(timings.addAll);

  final int budget = (1e6 / view.display.refreshRate).round();
  for (final (String name, int from, int to) in phases) {
    final Iterable<FrameTiming> mine = timings.where((FrameTiming t) {
      final int at = t.timestampInMicroseconds(FramePhase.vsyncStart);
      return at >= from && at < to;
    });
    final int late = mine
        .where((FrameTiming t) => t.buildDuration.inMicroseconds > budget || t.rasterDuration.inMicroseconds > budget)
        .length;
    final double build = mine.fold(
      0,
      (double m, FrameTiming t) =>
          m > t.buildDuration.inMicroseconds / 1000 ? m : t.buildDuration.inMicroseconds / 1000,
    );
    final double raster = mine.fold(
      0,
      (double m, FrameTiming t) =>
          m > t.rasterDuration.inMicroseconds / 1000 ? m : t.rasterDuration.inMicroseconds / 1000,
    );
    debugPrint(
      'BENCH $name: ${mine.length} frames, $late late, worst build ${build.toStringAsFixed(1)} ms, '
      'raster ${raster.toStringAsFixed(1)} ms',
    );
  }
  debugPrint('BENCH done');
}
