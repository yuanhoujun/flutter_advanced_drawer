part of '../flutter_advanced_drawer.dart';

/// AdvancedDrawer widget.
class AdvancedDrawer extends StatefulWidget {
  const AdvancedDrawer({
    Key? key,
    required this.child,
    required this.drawer,
    this.controller,
    this.backdropColor,
    this.backdrop,
    this.openRatio = 0.75,
    this.openScale = 0.85,
    this.initialDrawerScale = 0.75,
    this.drawerSlideRatio = 0,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve,
    this.childDecoration,
    this.animateChildDecoration = true,
    this.rtlOpening = false,
    this.disabledGestures = false,
    this.minFlingVelocity = 365.0,
    this.animationController,
    this.drawerCloseSemanticLabel = 'Close drawer',
  })  : assert(minFlingVelocity > 0),
        super(key: key);

  /// Child widget. (Usually widget that represent a screen)
  final Widget child;

  /// Drawer widget. (Widget behind the [child]).
  final Widget drawer;

  /// Controller that controls widget state.
  final AdvancedDrawerController? controller;

  /// Backdrop color.
  final Color? backdropColor;

  /// Backdrop widget for custom background.
  final Widget? backdrop;

  /// Opening ratio.
  final double openRatio;

  /// Opening ratio.
  final double openScale;

  /// How large the drawer segment should scale from.
  /// Set to 1 to disable drawer segment scale effect.
  final double initialDrawerScale;

  /// How far the drawer segment should slide with the content
  /// 0 = no slide distance
  /// 1 = slide from completely off screen
  final double drawerSlideRatio;

  /// Animation duration.
  final Duration animationDuration;

  /// Curve for automatic opening and closing. Dragging always follows the finger.
  final Curve? animationCurve;

  /// Child container decoration in open widget state.
  final BoxDecoration? childDecoration;

  /// Indicates that [childDecoration] might be animated or not.
  /// NOTICE: It may cause animation jerks.
  final bool animateChildDecoration;

  /// Opening from Right-to-left.
  final bool rtlOpening;

  /// Disable gestures.
  final bool disabledGestures;

  /// Minimum horizontal speed in logical pixels per second for a fling.
  /// Slower gestures use the halfway point to decide whether to open.
  final double minFlingVelocity;

  /// Controller that controls widget animation.
  final AnimationController? animationController;

  /// Provides a textual description of the close drawer action.
  ///
  /// This is used by accessibility frameworks to provide context
  /// for screen readers of what the close drawer action will do.
  ///
  /// if null, it will default to `'Close drawer'`
  final String? drawerCloseSemanticLabel;

  @override
  _AdvancedDrawerState createState() => _AdvancedDrawerState();
}

class _AdvancedDrawerState extends State<AdvancedDrawer>
    with TickerProviderStateMixin {
  final _spareController = AdvancedDrawerController();

  late AnimationController _spareAnimationController;
  late AnimationController _animationController;

  late Animation<double> _drawerScaleAnimation;
  late Animation<Offset> _childSlideAnimation;
  late Animation<double> _childScaleAnimation;
  late Animation<Offset> _drawerSlideAnimation;
  late Animation<Decoration> _childDecorationAnimation;

  bool _captured = false;

  @override
  void initState() {
    super.initState();

    _spareAnimationController = AnimationController(
      vsync: this,
      value: _controller.value.visible ? 1 : 0,
    );
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant AdvancedDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    (oldWidget.controller ?? _spareController)
        .removeListener(_handleControllerChanged);
    final previousAnimation = _animationController;
    final progress = previousAnimation.value;
    final wasAnimating = previousAnimation.isAnimating;
    if (oldWidget.animationController != widget.animationController) {
      previousAnimation.stop();
    }
    _initControllers();
    if (previousAnimation != _animationController) {
      _animationController.value = progress;
    }
    if (oldWidget.controller != widget.controller ||
        previousAnimation != _animationController && wasAnimating ||
        widget.disabledGestures && _captured) {
      _captured = false;
      _handleControllerChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backdropColor,
      child: GestureDetector(
        onHorizontalDragStart:
            widget.disabledGestures ? null : _handleDragStart,
        onHorizontalDragUpdate:
            widget.disabledGestures ? null : _handleDragUpdate,
        onHorizontalDragEnd: widget.disabledGestures ? null : _handleDragEnd,
        onHorizontalDragCancel:
            widget.disabledGestures ? null : _handleDragCancel,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              ValueListenableBuilder<AdvancedDrawerValue>(
                valueListenable: _controller,
                builder: (_, value, child) {
                  return ExcludeFocus(
                    excluding: !value.visible,
                    child: ExcludeSemantics(
                      excluding: !value.visible,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    if (widget.backdrop != null) widget.backdrop!,
                    Align(
                      alignment: widget.rtlOpening
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: SlideTransition(
                        position: _drawerSlideAnimation,
                        child: FractionallySizedBox(
                          widthFactor: widget.openRatio,
                          child: ScaleTransition(
                            scale: _drawerScaleAnimation,
                            alignment: widget.rtlOpening
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: RepaintBoundary(
                              child: Semantics(
                                container: true,
                                explicitChildNodes: true,
                                child: widget.drawer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SlideTransition(
                position: _childSlideAnimation,
                textDirection:
                    widget.rtlOpening ? TextDirection.rtl : TextDirection.ltr,
                child: ScaleTransition(
                  alignment: widget.rtlOpening
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  scale: _childScaleAnimation,
                  child: ValueListenableBuilder<AdvancedDrawerValue>(
                    valueListenable: _controller,
                    child: widget.child,
                    builder: (_, value, child) {
                      final childStack = Stack(
                        children: [
                          ExcludeFocus(
                            excluding: value.visible,
                            child: ExcludeSemantics(
                              excluding: value.visible,
                              child: RepaintBoundary(
                                child: child,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: value.visible,
                            child: Material(
                              color: Colors.transparent,
                              child: Semantics(
                                label: widget.drawerCloseSemanticLabel,
                                button: true,
                                container: true,
                                child: InkWell(
                                  onTap: _controller.hideDrawer,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  child: Container(),
                                ),
                              ),
                            ),
                          )
                        ],
                      );

                      if (widget.animateChildDecoration &&
                          widget.childDecoration != null) {
                        return AnimatedBuilder(
                          animation: _childDecorationAnimation,
                          builder: (_, child) {
                            return Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: _childDecorationAnimation.value,
                              child: child,
                            );
                          },
                          child: childStack,
                        );
                      }

                      return Container(
                        clipBehavior: widget.childDecoration != null
                            ? Clip.antiAlias
                            : Clip.none,
                        decoration: widget.childDecoration,
                        child: childStack,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AdvancedDrawerController get _controller {
    return widget.controller ?? _spareController;
  }

  void _initControllers() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..addListener(_handleControllerChanged);

    _animationController =
        widget.animationController ?? _spareAnimationController;

    _animationController.reverseDuration =
        _animationController.duration = widget.animationDuration;

    final parentAnimation = _animationController;

    _drawerScaleAnimation = Tween<double>(
      begin: widget.initialDrawerScale,
      end: 1.0,
    ).animate(parentAnimation);

    _drawerSlideAnimation = Tween<Offset>(
      begin: Offset(-widget.drawerSlideRatio, 0),
      end: Offset.zero,
    ).animate(parentAnimation);

    _childSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.openRatio, 0),
    ).animate(parentAnimation);

    _childScaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.openScale,
    ).animate(parentAnimation);

    _childDecorationAnimation = DecorationTween(
      begin: const BoxDecoration(),
      end: widget.childDecoration,
    ).animate(parentAnimation);
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    if (_controller.value.visible) {
      _animationController.animateTo(
        1,
        duration: widget.animationDuration,
        curve: widget.animationCurve ?? Curves.linear,
      );
    } else {
      _animationController.animateBack(
        0,
        duration: widget.animationDuration,
        curve: widget.animationCurve ?? Curves.linear,
      );
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _animationController.stop();
    _captured = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_captured) return;
    final travel = context.size!.width * widget.openRatio;
    if (travel <= 0) return;
    _animationController.value +=
        details.delta.dx / travel * (widget.rtlOpening ? -1 : 1);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_captured) return;
    _captured = false;
    final velocity =
        (details.primaryVelocity ?? 0) * (widget.rtlOpening ? -1 : 1);
    final open = velocity.abs() >= widget.minFlingVelocity
        ? velocity > 0
        : _animationController.value >= 0.5;
    if (open) {
      _controller.showDrawer();
    } else {
      _controller.hideDrawer();
    }
  }

  void _handleDragCancel() {
    if (!_captured) return;
    _captured = false;
    _handleControllerChanged();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _spareController.dispose();

    _spareAnimationController.dispose();

    super.dispose();
  }
}
