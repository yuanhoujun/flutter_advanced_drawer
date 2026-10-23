import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AdvancedDrawerController> mount(WidgetTester tester) async {
    final controller = AdvancedDrawerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AdvancedDrawer(
          controller: controller,
          openRatio: 0.7,
          openScale: 1,
          minFlingVelocity: 365,
          animationCurve: Curves.easeOutCubic,
          backdrop: const ColoredBox(color: Colors.white),
          drawer: const Center(child: Text('Menu')),
          child: const ColoredBox(
              key: ValueKey('content'),
              color: Colors.blue,
              child: SizedBox.expand()),
        ),
      ),
    );
    return controller;
  }

  testWidgets('short fast swipes open and close the drawer', (tester) async {
    final controller = await mount(tester);
    await tester.flingFrom(const Offset(100, 300), const Offset(100, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.value.visible, isTrue);
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 560);

    await tester.flingFrom(const Offset(700, 300), const Offset(-100, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.value.visible, isFalse);
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 0);
  });

  testWidgets('slow drags still use the halfway threshold', (tester) async {
    final controller = await mount(tester);
    Future<void> slowDrag(double distance) async {
      final gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.moveBy(Offset(distance, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await slowDrag(100);
    expect(controller.value.visible, isFalse);
    await slowDrag(350);
    expect(controller.value.visible, isTrue);
  });

  testWidgets('cancelled drag settles back and controller still works', (
    tester,
  ) async {
    final controller = await mount(tester);
    final gesture = await tester.startGesture(const Offset(100, 300));
    await gesture.moveBy(const Offset(200, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(controller.value.visible, isFalse);
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 0);
    controller.showDrawer();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 560);
    controller.hideDrawer();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 0);
  });
  testWidgets('RTL flings follow the opening direction', (tester) async {
    final controller = AdvancedDrawerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: AdvancedDrawer(
      controller: controller,
      rtlOpening: true,
      openRatio: 0.7,
      openScale: 1,
      drawer: const Text('menu'),
      child: const ColoredBox(
          key: ValueKey('content'),
          color: Colors.blue,
          child: SizedBox.expand()),
    )));
    await tester.flingFrom(const Offset(700, 300), const Offset(-100, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.value.visible, isTrue);
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, -560);
    await tester.flingFrom(const Offset(100, 300), const Offset(100, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.value.visible, isFalse);
  });

  testWidgets('drag stays linear in a constrained drawer across rebuilds',
      (tester) async {
    final controller = AdvancedDrawerController();
    addTearDown(controller.dispose);
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
        home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
          width: 400,
          height: 500,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AdvancedDrawer(
                controller: controller,
                openRatio: 0.7,
                openScale: 1,
                animationCurve: Curves.easeOutCubic,
                drawer: const Text('menu'),
                child: const ColoredBox(
                    key: ValueKey('content'),
                    color: Colors.blue,
                    child: SizedBox.expand()),
              );
            },
          )),
    )));
    final content = find.byKey(const ValueKey('content'));
    final gesture = await tester.startGesture(const Offset(30, 200));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    final before = tester.getTopLeft(content).dx;
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    expect(tester.getTopLeft(content).dx - before, closeTo(70, 0.01));
    final progress = tester.getTopLeft(content).dx;
    rebuild(() {});
    await tester.pump();
    expect(tester.getTopLeft(content).dx, progress);
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.value.visible, isTrue);
    expect(tester.getTopLeft(content).dx, 280);
  });

  testWidgets('a new drag interrupts an opening animation', (tester) async {
    final controller = await mount(tester);
    controller.showDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final gesture = await tester.startGesture(const Offset(700, 300));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    final position =
        tester.getTopLeft(find.byKey(const ValueKey('content'))).dx;
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, position);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 560);
  });

  testWidgets('disabled gestures ignore flings but controller still opens',
      (tester) async {
    final controller = AdvancedDrawerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: AdvancedDrawer(
      controller: controller,
      disabledGestures: true,
      drawer: const Text('menu'),
      child: const ColoredBox(color: Colors.blue, child: SizedBox.expand()),
    )));
    await tester.flingFrom(const Offset(100, 300), const Offset(100, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.value.visible, isFalse);
    controller.showDrawer();
    await tester.pumpAndSettle();
    expect(controller.value.visible, isTrue);
  });

  testWidgets('external controllers detach on replacement and disposal',
      (tester) async {
    final first = _InspectableController();
    final second = _InspectableController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget host(AdvancedDrawerController controller) => MaterialApp(
            home: AdvancedDrawer(
          controller: controller,
          openRatio: 0.7,
          openScale: 1,
          drawer: const Text('menu'),
          child: const ColoredBox(
              key: ValueKey('content'),
              color: Colors.blue,
              child: SizedBox.expand()),
        ));
    await tester.pumpWidget(host(first));
    await tester.pumpWidget(host(second));
    expect(first.hasRegisteredListeners, isFalse);
    second.showDrawer();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 560);
    await tester.pumpWidget(const SizedBox());
    expect(second.hasRegisteredListeners, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _InspectableController extends AdvancedDrawerController {
  bool get hasRegisteredListeners => hasListeners;
}
