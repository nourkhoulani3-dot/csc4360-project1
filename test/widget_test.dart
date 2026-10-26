import 'package:flutter_test/flutter_test.dart';
import 'package:plot/main.dart';

void main() {
  testWidgets('Plot app starts', (tester) async {
    await tester.pumpWidget(const PlotApp());

    expect(find.text('Add Activity'), findsOneWidget);
  });
}
