import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../LibZoteroStorage/entity/Item.dart';

class FileList extends StatefulWidget {
  final List<Item> items;
  const FileList({super.key,required this.items});

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  @override
  Widget build(BuildContext context) {
    return ListView();
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
      IconButton(onPressed: (){}, icon: Icon(Icons.more_vert),),

    ],),);
  }
}