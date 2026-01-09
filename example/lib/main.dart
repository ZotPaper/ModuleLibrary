import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:module_base/initializer.dart';
import 'package:module_base/stores/hive_stores.dart';
import 'package:module_base/utils/device/crash_reporter.dart';
import 'package:module_base/utils/tracking/dot_tracker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:module_library/LibZoteroStorage/stores/attachments_settings.dart';
import 'package:module_library/ModuleLibrary/page/launch_page.dart';
import 'package:module_library/ModuleLibrary/page/sync_page/sync_viewmodel.dart';
import 'package:module_library/ModuleLibrary/share_pref.dart';
import 'package:module_library/ModuleLibrary/store/library_settings.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/routers.dart';
import 'package:module_library/utils/local_zotero_credential.dart';
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
  await _loadEnv();
  await initSupabase();

  CrashReporter.init();

  // 添加DotTracker公共参数参数
  final zoteroId = await LocalZoteroCredential.getUserId();
  DotTracker.addCommonParam('user_info', {
    "zotero_id": zoteroId,
  });

  DotTracker
      .addDot("APP_INIT", description: "初始化APP")
      .report();
}

Future initSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  String supabaseUrl = "";
  String supabaseAnonKey = "";
  try {
    supabaseUrl = dotenv.get('SUPABASE_URL');
    supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
  } catch (e) {
    MyLogger.e("初始化Supabase失败：${e.toString()}");
    rethrow;
  }

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

Future<void> _loadEnv() async {
  const devEnVFileName = "dev.env";
  const productEnVFileName = "production.env";

  if (kReleaseMode) {
    MyLogger.d("加载生产环境配置");
    await dotenv.load(fileName: productEnVFileName);
  } else if (kDebugMode) {
    MyLogger.d("加载开发环境配置");
    await dotenv.load(fileName: devEnVFileName);  // Debug 加载开发配置
  }
}

