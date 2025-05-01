import 'ZoteroAPIService.dart';

class ZoteroAPI{
  final String apiKey;

  late ZoteroAPIService service;
  ZoteroAPI({required this.apiKey}){
    service = ZoteroAPIService(api:apiKey);
  }
}