import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Item> showItems = [];
  void _handleDrawerItemTap(DrawerBtn drawerBtn) {
    // 在这里处理侧边栏项的点击事件
    switch(drawerBtn){
      case DrawerBtn.home:
        // TODO: Handle this case.
      case DrawerBtn.favourites:
        // TODO: Handle this case.
      case DrawerBtn.library:
        // TODO: Handle this case.
      case DrawerBtn.firstLevel:
        // TODO: Handle this case.
      case DrawerBtn.variousTypes:
        // TODO: Handle this case.
      case DrawerBtn.thirdLevel:
        // TODO: Handle this case.
      case DrawerBtn.attachment:
        // TODO: Handle this case.
      case DrawerBtn.unfiled:
        // TODO: Handle this case.
      case DrawerBtn.publications:
        // TODO: Handle this case.
      case DrawerBtn.trash:
        // TODO: Handle this case.
    }
    // 你可以在这里添加导航、状态更新等逻辑
  }

  @override
  void initState(){
    super.initState();
    init();

  }
  void init() async{
    await SharedPref.init();
    bool isFirstStart = SharedPref.getBool(PrefString.isFirst,true);
    if(isFirstStart){
      print("isFirstStart");
      var zoteroData = ZoteroDataHttp( apiKey: "KsmSAwR7P4fXjh6QNjRETcqy",);
      var items = await zoteroData.getItems('16082509');
      setState(() {
        showItems.addAll(items);
      });

      ZoteroDataSql zoteroDataSql = ZoteroDataSql();
      zoteroDataSql.saveItems(items);
      await SharedPref.setBool(PrefString.isFirst, false);
    }else{
      var zoteroData = ZoteroDataHttp( apiKey: "KsmSAwR7P4fXjh6QNjRETcqy",);
      var items = await zoteroData.getItems('16082509');
      setState(() {
        showItems.addAll(items);
      });
    }

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
      drawer: CustomDrawer(onItemTap: _handleDrawerItemTap),
      appBar: pageAppBar(leadingIconTap: (){
        _scaffoldKey.currentState?.openDrawer();
        },filterMenuTap: (){

        },tagsTap: (){

      }),
      body: Column(children: [
        searchLine(),
        Expanded(child: Container(width: double.infinity,child:
        ListView.builder(itemCount: showItems.length,  // 列表项数量
          itemBuilder: (context, index) {
            final item = showItems[index]; // 获取当前项数据
            return fileOneLine(item);
          },),)),


      ],)
    );
  }
  final TextEditingController _searchController = TextEditingController();
  String _selectDrawerTitle = "Home";



  Widget searchLine(){
    return Container(
      color: ResColor.bgColor,
      height: 30,width: double.infinity,child: Row(children: [
      Container(width: 20,),
      Icon(Icons.search),
      Expanded(child:
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search as you type',
          border: InputBorder.none,
        ),
      )),
      Container(width: 20,),
    ],),);
  }
  Widget fileOneLine(Item item){
    return Container(padding: const EdgeInsets.all(5),width: double.infinity, child: Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset("assets/ic_round.png",width: 40,height: 40,),
      ),
      Container(width: 5,),
      Expanded(child: Column(children: [
        Text(item.getTitle(),maxLines: 2,),
        Text(item.getAuthor(),maxLines: 1,style: TextStyle(color: Colors.grey),),
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

    ],),);
  }
}