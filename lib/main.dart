import 'package:flutter/widgets.dart';
import 'package:reziphay_mobile/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await bootstrap();
  runApp(app);
}
