import 'package:module_library/LibZoteroApi/Model/CollectionPojo.dart';

class ZoteroAPICollectionsResponse{

  final List<CollectionPOJO> data;

  final int statusCode;

  final int LastModifiedVersion;

  final int totalResults;

  final bool isCached;

  ZoteroAPICollectionsResponse(this.data,  this.statusCode, this.totalResults, this.LastModifiedVersion, this.isCached);
}