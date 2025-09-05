import 'package:module_base/utils/store/iface.dart';

class LibraryStore extends HiveStore {
  LibraryStore() : super('library');

  late final sortMethod = const PrefPropDefault('sort_method', 'TITLE');

  late final sortDirection = const PrefPropDefault('SORT_DIRECTION', "ASCENDING");

  late final showOnlyWithPdfs = const PrefPropDefault('is_showing_only_with_pdfs', false);

  late final showOnlyWithNotes = const PrefPropDefault('is_showing_only_with_notes', false);

}

