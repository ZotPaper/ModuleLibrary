class ZoteroAPIItemsResponse{

  final List<dynamic> data;

  final int statusCode;

  final int LastModifiedVersion;

  final int totalResults;

  final bool isCached;

  ZoteroAPIItemsResponse(this.data,  this.statusCode, this.totalResults, this.LastModifiedVersion, this.isCached);
}