// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadow_shat/shadow_chat_screen.dart' show ShadowChatScreen;

import 'package:shadow_shat/main.dart';

Future<void> _openJourneyToFinalDay(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
  expect(find.text('افتح الباب'), findsOneWidget);
  expect(find.text('OPEN THE DOOR'), findsOneWidget);
  expect(find.text('الرجوع'), findsOneWidget);
  expect(find.text('GO BACK'), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-door-closed')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-left-door-leaf')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-right-door-leaf')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-chat-input')), findsNothing);
  final closedFrameRect = tester.getRect(
    find.byKey(const ValueKey('shadow-door-closed')),
  );

  await tester.tap(find.byKey(const ValueKey('open-door')));
  await tester.pump();
  expect(find.byKey(const ValueKey('shadow-door-open')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-left-door-leaf')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-right-door-leaf')), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 850));
  expect(
    tester.getRect(find.byKey(const ValueKey('shadow-door-open'))),
    closedFrameRect,
  );
  final leftLeafTransform = tester
      .widget<Transform>(find.byKey(const ValueKey('shadow-left-door-leaf')))
      .transform;
  final rightLeafTransform = tester
      .widget<Transform>(find.byKey(const ValueKey('shadow-right-door-leaf')))
      .transform;
  expect(leftLeafTransform[2], greaterThan(0));
  expect(rightLeafTransform[2], lessThan(0));

  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
  expect(find.text('اليوم الأول • المرحلة الأولى'), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-chat-input')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-chat-send')), findsOneWidget);

  const nextDayTitles = [
    'اليوم الثاني • المرحلة الثانية',
    'اليوم الثالث • المرحلة الثالثة',
    'اليوم الرابع • المرحلة الرابعة',
  ];
  for (final title in nextDayTitles) {
    await tester.tap(find.byKey(const ValueKey('next-day')));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
  }
}

void main() {
  test('duplicate Firebase initialization is ignored safely', () {
    final duplicateError = FirebaseException(
      plugin: 'firebase_core',
      code: 'duplicate-app',
      message: 'A Firebase App named "[DEFAULT]" already exists',
    );

    expect(isDuplicateFirebaseInitializationError(duplicateError), isTrue);
    expect(
      isDuplicateFirebaseInitializationError(
        FirebaseException(
          plugin: 'firebase_core',
          code: 'unknown',
          message: 'other error',
        ),
      ),
      isFalse,
    );
  });

  test(
    'Firebase web config falls back to demo mode when placeholder is used',
    () {
      expect(hasUsableFirebaseWebConfig('REPLACE_WITH_WEB_API_KEY'), isFalse);
      expect(hasUsableFirebaseWebConfig('abc123validkey'), isTrue);
      expect(hasUsableFirebaseWebConfig(''), isFalse);
    },
  );

  test('Firebase add failures expose the real error code', () {
    expect(
      firebaseWriteFailureMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('permission-denied'),
    );
  });

  test('regular contact action blocks duplicate request states', () {
    expect(
      determineRegularContactAction(myStatus: 'pending', otherStatus: 'none'),
      'pending',
    );
    expect(
      determineRegularContactAction(myStatus: 'none', otherStatus: 'incoming'),
      'incoming',
    );
    expect(
      determineRegularContactAction(myStatus: 'accepted', otherStatus: 'none'),
      'accepted',
    );
    expect(
      determineRegularContactAction(myStatus: 'rejected', otherStatus: 'none'),
      'rejected',
    );
  });

  test('display names are sanitized consistently before saving', () {
    expect(sanitizeDisplayName('   علي   أحمد   '), 'علي أحمد');
    expect(sanitizeDisplayName(''), isEmpty);
  });

  test(
    'secret member removal policy allows group removal and owner-only room removal',
    () {
      expect(
        canRemoveSecretMember(
          isGroup: true,
          ownerVerified: false,
          isOwnerUser: false,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: false,
          isOwnerUser: true,
        ),
        isFalse,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: true,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: false,
        ),
        isFalse,
      );
    },
  );

  testWidgets('Shadow Chat app starts', (WidgetTester tester) async {
    appLockEnabledNotifier.value = true;
    appLockPasswordNotifier.value = await hashPassword(
      'test-app-lock-password',
    );
    await tester.pumpWidget(const MaterialApp(home: AppLockGate()));

    expect(find.byType(AppLockGate), findsOneWidget);
    expect(find.text('تغيير كلمة سر قفل التطبيق'), findsOneWidget);
  });

  testWidgets('closed door fills a phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    final doorSize = tester.getSize(
      find.byKey(const ValueKey('shadow-door-closed')),
    );

    expect(doorSize.width, 390);
    expect(doorSize.height, 844);
    expect(
      find.byKey(const ValueKey('shadow-door-black-background')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('shadow-left-door-leaf')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shadow-right-door-leaf')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Image>(find.byKey(const ValueKey('shadow-door-image-left')))
          .fit,
      BoxFit.cover,
    );
    expect(
      tester
          .widget<Image>(find.byKey(const ValueKey('shadow-door-image-right')))
          .fit,
      BoxFit.cover,
    );
  });

  testWidgets('door frame stays still while only the leaves rotate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));

    final closedFrameRect = tester.getRect(
      find.byKey(const ValueKey('shadow-door-frame')),
    );
    final frameOverlayStack = tester.widget<Stack>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('shadow-door-frame')),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(
      frameOverlayStack.children.last.key,
      const ValueKey('shadow-door-frame'),
    );
    final frameOverlay = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('shadow-door-frame')),
    );
    expect(
      (frameOverlay.decoration as BoxDecoration).boxShadow,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('open-door')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));

    final openFrameRect = tester.getRect(
      find.byKey(const ValueKey('shadow-door-frame')),
    );

    expect(openFrameRect, closedFrameRect);
    final leftLeafTransform = tester
        .widget<Transform>(find.byKey(const ValueKey('shadow-left-door-leaf')))
        .transform;
    final rightLeafTransform = tester
        .widget<Transform>(find.byKey(const ValueKey('shadow-right-door-leaf')))
        .transform;
    expect(leftLeafTransform[2], greaterThan(0));
    expect(rightLeafTransform[2], lessThan(0));
  });

  testWidgets('door opens into all stages and the left path ends in doom', (
    WidgetTester tester,
  ) async {
    await _openJourneyToFinalDay(tester);
    expect(find.byKey(const ValueKey('ending-doom')), findsOneWidget);
    expect(find.byKey(const ValueKey('ending-victory')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ending-doom')));
    await tester.pumpAndSettle();
    expect(find.text('هلاك إلى الأبد'), findsOneWidget);
  });

  testWidgets('the right path ends in victory', (WidgetTester tester) async {
    await _openJourneyToFinalDay(tester);

    await tester.tap(find.byKey(const ValueKey('ending-victory')));
    await tester.pumpAndSettle();
    expect(find.text('انتصرت في الرحلة'), findsOneWidget);
  });

  testWidgets('chat list opens the Shadow Chat door screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    firebaseReady = false;
    await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محادثة الظل'));
    await tester.pumpAndSettle();

    expect(find.text('افتح الباب'), findsOneWidget);
    expect(find.text('الرجوع'), findsOneWidget);
  });

  testWidgets('local demo starts without initializing Firebase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'startup_intro_seen': true,
      'has_seen_onboarding': true,
    });
    firebaseReady = false;
    appLockEnabledNotifier.value = false;
    await tester.pumpWidget(const ShadowChatApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatListScreen), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('محادثة الظل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('افتح الباب'), findsOneWidget);
    expect(find.text('الرجوع'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('local demo restores dark mode on startup', () async {
    SharedPreferences.setMockInitialValues({darkModeKey: false});

    await loadAppLockSettings();
    final preferences = await SharedPreferences.getInstance();

    expect(globalDarkModeNotifier.value, isTrue);
    expect(preferences.getBool(darkModeKey), isTrue);
  });
}
