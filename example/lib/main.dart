import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroStorage/entity/Item.dart';
import 'package:module_library/ModuleItemDetail/page/item_details_page.dart';
import 'package:module_library/ModuleLibrary/page/LibraryPage.dart';
import 'package:module_library/ModuleLibrary/page/launch_page.dart';
import 'package:module_library/ModuleLibrary/page/select_collection_page/collection_select_page.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/library_viewmodel.dart';
import 'package:module_library/ModuleTagManager/page/item_tagsmanager_page.dart';
import 'package:provider/provider.dart';

void main() {

  runApp(
    ChangeNotifierProvider(
      create: (_) => LibraryViewModel(),
      child: MyApp(),
    ),);
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
            fontFamily: 'Bebas-Regular',
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
        'collectionSelector': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            List<String> collectionKeys = [];
            var multiSelect = true;

            try {
              collectionKeys = arguments['initialSelected'] as List<String>;
              multiSelect = arguments['isMultiSelect'] as bool;
            } catch (e) {
              MyLogger.e('Error: $e');
            }
            return CollectionSelector(parentCollections: collectionKeys, isMultiSelect: multiSelect,);
          }
          return CollectionSelector();
        },
      },
    );
  }
}
