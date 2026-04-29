import 'package:flutter_test/flutter_test.dart';
import 'package:kenzy/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Initial load test', (WidgetTester tester) async {
    // On fournit les dépendances minimales pour que le test ne crash pas
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MyApp(),
      ),
    );

    // On vérifie simplement que l'application a démarré (SplashScreen ou autre)
    expect(find.byType(MyApp), findsOneWidget);
  });
}
