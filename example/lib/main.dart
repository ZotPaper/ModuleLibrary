import 'package:flutter/material.dart';
import 'package:module_base/initializer.dart';
import 'package:module_base/stores/hive_stores.dart';
import 'package:module_base/utils/log/app_log_event.dart';
import 'package:module_library/LibZoteroStorage/stores/attachments_settings.dart';
import 'package:module_library/ModuleLibrary/page/launch_page.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_viewmodel.dart';
import 'package:module_library/ModuleLibrary/share_pref.dart';
import 'package:module_library/ModuleLibrary/store/library_settings.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/routers.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LibraryViewModel()),
        ChangeNotifierProvider(create: (context) => SyncViewModel()),
      ],
      child: MyApp(),
    ),);
}

Future<void> init() async {
  BaseInitializer.addStore(Stores.KEY_LIBRARY, LibraryStore());
  BaseInitializer.addStore(Stores.KEY_ATTACHMENT, AttachmentStore());
  await BaseInitializer.init();
  await SharedPref.init();
  await initSupabase();

  logEvent(message: "初始化APP");
}

Future initSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  // const String supabaseUrl = 'https://supabase.zotpaper.cn/project/default';
  // const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiem90IiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NjE3NTM2MDAsImV4cCI6MTkxOTUyMDAwMH0.lUi5Q0Q9g-I3hzrovlsXxs2MD4JFkKplDvRWfXhHCcw';

  const String supabaseUrl = 'https://sgbffrmouhsrrewbuiep.supabase.co/';
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZmcm1vdWhzcnJld2J1aWVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NTc3ODYsImV4cCI6MjA3NzMzMzc4Nn0.LHGDNGWqmnzqyAwiP4BSZRztsjho0jcQ7ReXBepoUZE';

  MyLogger.d("=======初始化Supabase annonKey: $supabaseAnonKey===");

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget appBuilder() {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [globalRouteObserver], // 注册RouteObserver以支持页面返回检测
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
