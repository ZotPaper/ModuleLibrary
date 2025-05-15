import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module/LibZoteroStorage/entity/Collection.dart';
import 'package:module/LibZoteroStorage/entity/ItemData.dart';
import 'package:module/LibZoteroStorage/entity/ItemInfo.dart';
import 'package:module/ModuleLibrary/api/ZoteroDataHttp.dart';
import 'package:module/ModuleLibrary/api/ZoteroDataSql.dart';
import 'package:module/ModuleLibrary/res/ResColor.dart';
import 'package:module/ModuleLibrary/share_pref.dart';

import '../../LibZoteroApi/ZoteroAPIService.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';


class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _userId = "16082509";
  final _apiKey = "KsmSAwR7P4fXjh6QNjRETcqy";
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Item> _items = [];
  final List<Item> _showItems = [];
  final List<Collection> _collections = [];

  void _handleDrawerItemTap(DrawerBtn drawerBtn) {
    // 在这里处理侧边栏项的点击事件
    switch (drawerBtn) {
      case DrawerBtn.home:
        _resetShowItems();
        for (var collection in _collections) {
          _showItems.add(Item(
            itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
              version: collection.version, deleted: false),
            itemData: [ItemData(id: 0, parent: collection.key, name: 'title', value: collection.name, valueType: "String")],
            creators: [],
            tags: [],
            collections: [],
          ));
        }
        _showItems.addAll(_items);
        break;
      case DrawerBtn.favourites:
        // TODO: Handle this case.
      case DrawerBtn.library:
        _resetShowItems();
        _showItems.addAll(_items);
        break;
      case DrawerBtn.unfiled:
        _resetShowItems();
        final tempItems = _items.where((item) => item.collections.isEmpty).toList();
        _showItems.addAll(tempItems);
        break;
      case DrawerBtn.publications:
        _resetShowItems();
        final tempItems = _items.where((item) {
          return item.data.containsKey("inPublications") && item.data["inPublications"] == "true";
        }).toList();
        _showItems.addAll(tempItems);
        break;
      case DrawerBtn.trash:
        // TODO: Handle this case.
    }
    setState(() {});
  }

  void _resetShowItems() {
    _showItems.clear();
  }

  void _handleCollectionTap(Collection collection) async{
    ZoteroDataSql zoteroDataSql = ZoteroDataSql();
    var items = await zoteroDataSql.getItemsInCollection(collection.key);
    setState(() {
      _showItems.clear();
      _showItems.addAll(items);
    });
  }
  @override
  void initState(){
    super.initState();
    init();

  }
  void init() async {
    ZoteroDataSql zoteroDataSql = ZoteroDataSql();
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst, true);
    if (isFirstStart) {
      print("isFirstStart");
      var zoteroData = ZoteroDataHttp(apiKey: _apiKey);
      var collections = await zoteroData.getCollections(0, _userId, 0);
      await zoteroDataSql.saveCollections(collections);
      _collections.addAll(collections);

      for (var collection in collections) {
        _showItems.add(Item(
          itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
            version: collection.version, deleted: false),
          itemData: [ItemData(id: 0, parent: collection.key, name: 'title', value: collection.name, valueType: "String")],
          creators: [],
          tags: [],
          collections: [],
        ));
      }

      _items = await zoteroData.getItems(_userId);
      _showItems.addAll(_items);
      await zoteroDataSql.saveItems(_items);
      await SharedPref.setBool(PrefString.isFirst, false);
    } else {
      _items = await zoteroDataSql.getItems();
      var collections = await zoteroDataSql.getCollections();
      for (var col in collections) {
        print(col.name);
      }

      _resetShowItems();
      for (var collection in collections) {
        _showItems.add(Item(
          itemInfo: ItemInfo(id: 0, itemKey: collection.key, groupId: collection.groupId,
            version: collection.version, deleted: false),
          itemData: [ItemData(id: 0, parent: collection.key, name: "title", value: collection.name, valueType: "String")],
          creators: [],
          tags: [],
          collections: [],
        ));
      }

      _showItems.addAll(_items);
      _collections.addAll(collections);
    }

    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: ResColor.bgColor,
      key: _scaffoldKey,
      drawerEnableOpenDragGesture : false,
      drawer: CustomDrawer(collections: _collections,onItemTap: _handleDrawerItemTap,onCollectionTap: _handleCollectionTap,),
      appBar: pageAppBar(leadingIconTap: (){
        _scaffoldKey.currentState?.openDrawer();
        },filterMenuTap: (){

        },tagsTap: (){

      }),
      body: Column(children: [
        searchLine(),
        Expanded(child: Container(color: ResColor.bgColor,width: double.infinity,child:
        ListView.builder(itemCount: _showItems.length,  // 列表项数量
          itemBuilder: (context, index) {
            final item = _showItems[index]; // 获取当前项数据
            return fileOneLine(item);
          },),)),


      ],)
    );
  }
  final TextEditingController _searchController = TextEditingController();
  String _selectDrawerTitle = "Home";

  /// 搜索框
  Widget searchLine(){
    return Container(
      color: ResColor.bgColor,
      height: 48,
      width: double.infinity,child: Row(children: [
      Container(width: 20,),
      const Icon(Icons.search),
      Expanded(child:
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search as you type',
          border: InputBorder.none,
        ),
      )),
      Container(width: 20,),
    ],),);
  }

  Widget fileOneLine(Item item){
    return InkWell(
      onTap: () {

      },
      child: Container(padding: const EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 10),width: double.infinity, child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/ic_round.png",width: 40,height: 40,),
        ),
        Container(width: 5,),
        Expanded(child: Column(children: [
          Container(width: double.infinity,child: Text(item.getTitle(),maxLines: 2,),),
          Container(width: double.infinity,child: Text(item.getAuthor(),maxLines: 1,style: TextStyle(color: Colors.grey),),),

        ],),
        ),
        Material(child: Ink(child: InkWell(
          onTap: (){
            print("pdf tap");
          },
          child: Container(color: ResColor.bgColor,child:
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/pdf.png",
                width: 20,
                height: 20,
                fit: BoxFit.fitWidth,
              ),
        ),),),),),
        IconButton(onPressed: (){}, icon: Icon(Icons.more_vert),),

      ],),),
    );
  }
}