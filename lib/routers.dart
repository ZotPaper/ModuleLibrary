import 'package:bruno/bruno.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'LibZoteroStorage/entity/Item.dart';
import 'LibZoteroStorage/entity/Note.dart';
import 'ModuleItemDetail/page/item_details_page.dart';
import 'ModuleLibrary/page/LibraryPage.dart';
import 'ModuleLibrary/page/launch_page.dart';
import 'ModuleLibrary/page/select_collection_page/collection_select_page.dart';
import 'ModuleLibrary/page/sync_page/sync_page.dart';
import 'ModuleLibrary/utils/my_logger.dart';
import 'ModuleNoteEdit/note_edit_page.dart';
import 'ModuleTagManager/page/item_tagsmanager_page.dart';

// 全局RouteObserver，用于监听页面路由变化
final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();

class MyRouter {
  // 单例模式
  static final MyRouter instance = MyRouter._internal();
  factory MyRouter() => instance;
  MyRouter._internal();

  static const String PAGE_LAUNCH= 'launchPage';
  static const String PAGE_LIBRARY = 'libraryPage';
  static const String PAGE_NOTE_EDIT = 'noteEditPage';

  bool _enableExceptionCatch = false;

  Function(BuildContext, String, Map<String, dynamic>?)? _onInterceptNavigatior;

  Function(BuildContext, String, Map<String, dynamic>?)? _onInterceptNavigatiorReplacement;

  void setOnInterceptNavigator(Function(BuildContext, String, Map<String, dynamic>?) onInterceptNavigator) {
    _onInterceptNavigatior = onInterceptNavigator;
  }

  void setOnInterceptNavigatorReplacement(Function(BuildContext, String, Map<String, dynamic>?) onInterceptNavigatorReplacement) {
    _onInterceptNavigatiorReplacement = onInterceptNavigatorReplacement;
  }

  dynamic pushNamed(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    if (_onInterceptNavigatior != null) {
      _onInterceptNavigatior!(context, routeName, arguments);
      return;
    }

    try {
      return Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } catch (e) {
      MyLogger.e('Error: $e');

      if (!_enableExceptionCatch) {
        rethrow;
      }

      BrnToast.show("跳转到目标页面失败：$routeName", context);
      return null;
    }

    return null;
  }

  dynamic pushReplacementNamed(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    if (_onInterceptNavigatiorReplacement != null) {
      _onInterceptNavigatiorReplacement!(context, routeName, arguments);
      return;
    }

    try {
      return Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    } catch (e) {
      MyLogger.e('Error: $e');

      if (!_enableExceptionCatch) {
        rethrow;
      }

      BrnToast.show("跳转到目标页面失败：$routeName", context);
      return null;
    }

    return null;
  }

}

Map<String, WidgetBuilder> libraryRouters() {
  return {
    'launchPage': (context) => const LaunchPage(),
    'libraryPage': (context) => const LibraryPage(),
    'syncingPage': (context) => const SyncPageFragment(),
    'tagsManagerPage': (context) => const TagsManagerPage(),
    'itemDetailPage': (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        var item = arguments['item'] as Item;
        return ItemDetailsPage(item);
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
    MyRouter.PAGE_NOTE_EDIT: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      Note note = Note(parent: '', key: '', note: '');
      if (arguments is Map<String, dynamic>) {
        note = arguments['note'] as Note;
      }
      return NoteEditPage(note);
    }
  };
}