import 'package:flutter/material.dart';
import 'package:module_library/ModuleLibrary/page/launch_page.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_viewmodel.dart';
import 'package:module_library/ModuleLibrary/share_pref.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/routers.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPref.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LibraryViewModel()),
        ChangeNotifierProvider(create: (context) => SyncViewModel()),
      ],
      child: MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget appBuilder() {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            // fontSize: 16,
            fontFamily: 'Bebas-Regular',
            fontWeight: FontWeight.normal,
            // color: Colors.black,
          ),
        ),
      ),
      home: const LaunchPage(),
      routes: libraryRouters()
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return appBuilder();
  }
}
