import 'package:flutter_test/flutter_test.dart';
import 'package:villee/main.dart';

void main(){
  testWidgets('初期画面が表示される',(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text("Firebase initialization completed"),
      findsOneWidget,
    );
  });
}