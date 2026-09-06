import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_lord/screens/app_screen.dart';

void main() {
  testWidgets('renders the MangaLord home navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const AppScreen(),
      ),
    );

    expect(find.text('Manga Starz'), findsOneWidget);
    expect(find.text('اكتشاف'), findsOneWidget);
    expect(find.text('مكتبتي'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
  });
}
