import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'model.dart';

/// Observes and moves a sheet.
///
/// Pass it to [OnaBottomSheet.controller] (or [RawSheet.controller]); its [value] is then the sheet's offset from the
/// bottom of the viewport, null until the sheet is laid out, and [metrics] the rest of its geometry. Listeners hear
/// every change of position. Dispose it when the widget that created it goes.
class OnaSheetController extends ChangeNotifier implements ValueListenable<double?> {
  SheetModel? _client;

  /// A notifier which notifies listeners immediately when the [_client] fires.
  ///
  /// This is necessary to keep separate the listeners that should be
  /// notified immediately when the [_client] fires, and the ones that should
  /// not be notified during the middle of a frame.
  final _immediateListeners = ChangeNotifier();

  @override
  double? get value => _client?.offset;

  /// The current metrics of the sheet.
  SheetMetrics? get metrics => switch (_client) {
    final it? when it.hasMetrics => it.copyWith(),
    _ => null,
  };

  /// Whether a [SheetModel] is attached to this controller.
  bool get hasClient => _client != null;

  @override
  void addListener(VoidCallback listener, {bool fireImmediately = false}) {
    if (fireImmediately) {
      _immediateListeners.addListener(listener);
    } else {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _immediateListeners.removeListener(listener);
    super.removeListener(listener);
  }

  /// Connects the controller to the sheet [position]; called by the sheet itself.
  void attach(SheetModel position) {
    if (_client case final oldPosition?) {
      detach(oldPosition);
    }

    _client = position..addListener(notifyListeners);
  }

  /// Disconnects the controller from [position] if it is the one attached; called by the sheet itself.
  void detach(SheetModel? position) {
    if (position == _client) {
      position?.removeListener(notifyListeners);
      _client = null;
    }
  }

  @override
  void dispose() {
    detach(_client);
    _immediateListeners.dispose();
    super.dispose();
  }

  /// Moves the sheet to [to] over [duration] on [curve]; completes when it arrives or is interrupted.
  Future<void> animateTo(
    SheetOffset to, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_client != null);
    return _client!.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void notifyListeners() {
    _immediateListeners.notifyListeners();

    // Avoid notifying listeners during the middle of a frame.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.postFrameCallbacks:
        super.notifyListeners();

      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          super.notifyListeners();
        });
    }
  }
}

/// Gives the sheets below it a shared [OnaSheetController], created and disposed for you.
class DefaultOnaSheetController extends StatefulWidget {
  /// Creates a scope with its own controller.
  const DefaultOnaSheetController({super.key, required this.child});

  /// The subtree the controller is shared with.
  final Widget child;

  @override
  State<DefaultOnaSheetController> createState() => _DefaultSheetControllerState();

  /// The controller of the nearest scope, or null when there is none.
  static OnaSheetController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OnaSheetControllerScope>()?.controller;
  }

  /// The controller of the nearest scope; asserts there is one.
  static OnaSheetController of(BuildContext context) {
    final controller = maybeOf(context);

    assert(
      (() {
        if (controller == null) {
          throw FlutterError(
            'No OnaSheetControllerScope ancestor could be found starting '
            'from the context that was passed to DefaultOnaSheetController.of(). '
            'The context used was:\n'
            '$context',
          );
        }
        return true;
      })(),
    );

    return controller!;
  }
}

class _DefaultSheetControllerState extends State<DefaultOnaSheetController> {
  late final OnaSheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnaSheetController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnaSheetControllerScope(controller: _controller, child: widget.child);
  }
}

@internal
class OnaSheetControllerScope extends InheritedWidget {
  const OnaSheetControllerScope({super.key, required this.controller, required super.child});

  final OnaSheetController controller;

  @override
  bool updateShouldNotify(OnaSheetControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
