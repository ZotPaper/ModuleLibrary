import 'package:flutter/material.dart';
import 'package:module_library/ModuleItemDetail/page/item_details_page.dart';
import 'package:module_library/ModuleLibrary/page/launch_page.dart';
import 'package:module_library/ModuleTagManager/page/item_tagsmanager_page.dart';

import 'LibZoteroStorage/entity/Item.dart';
import 'ModuleLibrary/page/LibraryPage.dart';
import 'ModuleLibrary/share_pref.dart';

void main() {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
            fontWeight: FontWeight.normal,
            // color: Colors.black,
          ),
        ),
      ),
      home: const LaunchPage(),
      routes: {
        'libraryPage': (context) => const LibraryPage(),
        'tagsManagerPage': (context) => const TagsManagerPage(),
        'itemDetailPage': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Item) {
            return ItemDetailsPage(arguments);
          } else {
            // 可以抛出错误或跳转到错误页面
            throw Exception('Invalid argument type for itemDetailPage');
          }
        },
      },
    );
  }
}
