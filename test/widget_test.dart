import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strange_shogi/app.dart';

void main() {
  testWidgets('ホームから盤面確認へ進める', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StrangeShogiApp()));
    expect(find.text('ヘンな将棋'), findsOneWidget);
    expect(find.text('新しい対局'), findsOneWidget);

    await tester.tap(find.text('新しい対局'));
    await tester.pumpAndSettle();

    expect(find.text('1. 盤面を確認'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.textContaining('シード:'), findsOneWidget);
  });
}
