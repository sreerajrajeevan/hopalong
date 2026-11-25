// HopAvatar: local picked photos must render via FileImage, not
// NetworkImage (which silently failed and showed a blank circle).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopalong/widgets/common.dart';

const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  test('isLocalPath distinguishes picked files from URLs', () {
    expect(HopAvatar.isLocalPath('/storage/emulated/0/photo.jpg'), isTrue);
    expect(HopAvatar.isLocalPath('file:///tmp/photo.jpg'), isTrue);
    expect(
        HopAvatar.isLocalPath('https://randomuser.me/api/portraits/men/32.jpg'),
        isFalse);
    expect(HopAvatar.isLocalPath(''), isFalse);
  });

  testWidgets('local photo file renders as FileImage',
      (WidgetTester tester) async {
    final file = File(
        '${Directory.systemTemp.path}/hopalong_avatar_test.png')
      ..writeAsBytesSync(base64Decode(_tinyPngBase64));
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HopAvatar(photoUrl: '', name: 'Meera Nair')),
    ));
    // Pump with the real local path via a fresh widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HopAvatar(photoUrl: file.path, name: 'Meera Nair')),
    ));
    await tester.pump();

    final avatar =
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundImage, isA<FileImage>());
  });

  testWidgets('missing local file falls back to initials',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
          body: HopAvatar(
              photoUrl: '/tmp/hopalong_does_not_exist.jpg',
              name: 'Meera Nair')),
    ));
    await tester.pump();

    final avatar =
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundImage, isNull);
    expect(find.text('MN'), findsOneWidget);
  });

  testWidgets('https URL still renders as NetworkImage',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
          body: HopAvatar(
              photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
              name: 'Arun Kumar')),
    ));
    await tester.pump();

    final avatar =
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundImage, isA<NetworkImage>());
  });
}
