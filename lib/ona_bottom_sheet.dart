/// Bottom sheets that move like the platform's own, by Ona.
///
/// - [showOnaBottomSheet] shows a modal sheet; [OnaBottomSheetRoute] and [OnaBottomSheetPage] give full control and
///   declarative navigation.
/// - [OnaBottomSheet] is the sheet, styled by [OnaBottomSheetTheme], solid or liquid glass ([OnaSheetStyle]); [OnaSheetScaffold] lays out its header, body and
///   footer; [OnaSheetGrabber] is its handle.
/// - [OnaSheetViewport] keeps a sheet on a screen without a route (an always-on, Maps-style sheet).
/// - [SheetDetents] and [SheetOffset] say where a sheet rests; [SheetPhysics] how it moves; [OnaSheetController]
///   observes and moves it.
/// - [RawSheet] is the unstyled building block underneath.
library;

export 'src/foundation/controller.dart' hide OnaSheetControllerScope;
export 'src/foundation/model.dart'
    hide
        ImmutableSheetLayout,
        ImmutableSheetMetrics,
        ImmutableViewportLayout,
        SheetContext,
        SheetModel,
        SheetModelConfig,
        SheetModelView;
export 'src/foundation/notification.dart';
export 'src/gestures/drag.dart' hide SheetDragController, SheetDragControllerTarget;
export 'src/gestures/draggable.dart' show SheetDragConfiguration;
export 'src/modal/route.dart';
export 'src/modal/show.dart';
export 'src/physics/detents.dart';
export 'src/physics/physics.dart';
export 'src/scroll/scrollable.dart'
    hide
        BallisticScrollDrivenSheetActivity,
        DragScrollDrivenSheetActivity,
        HoldScrollDrivenSheetActivity,
        ScrollAwareSheetModelMixin,
        SheetScrollPosition;
export 'src/theme/style.dart';
export 'src/theme/theme.dart';
export 'src/widgets/bottom_sheet.dart';
export 'src/widgets/decorations.dart';
export 'src/widgets/keyboard_dismissible.dart';
export 'src/widgets/offset_driven_animation.dart';
export 'src/widgets/raw_sheet.dart' hide DraggableScrollableSheetContent;
export 'src/widgets/scaffold.dart';
export 'src/widgets/viewport.dart' hide BareSheet, DefaultSheetDecoration, OnaSheetViewportState;
