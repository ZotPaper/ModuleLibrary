import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module/ModuleLibrary/model/list_entry.dart';
import 'package:module/ModuleLibrary/model/page_type.dart';
import 'package:module/ModuleLibrary/page/blank_page.dart';
import 'package:module/ModuleLibrary/page/sync_page/sync_page.dart';
import 'package:module/ModuleLibrary/res/ResColor.dart';
import 'package:module/ModuleLibrary/viewmodels/library_viewmodel.dart';

import 'LibraryUI/appBar.dart';
import 'LibraryUI/drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LibraryViewModel _viewModel = LibraryViewModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: ResColor.bgColor,
          key: _scaffoldKey,
          drawerEnableOpenDragGesture: false,
          drawer: CustomDrawer(
            collections: _viewModel.displayedCollections,
            onItemTap: _viewModel.handleDrawerItemTap,
            onCollectionTap: (collection) {
              _viewModel.handleCollectionTap(collection);
            }, // 如果有需要再实现
          ),
          appBar: pageAppBar(
            title: _viewModel.title,
            leadingIconTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            filterMenuTap: () {},
            tagsTap: () {},
          ),
          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPageContent(),
        );
      }
    );
  }

  Widget _buildPageContent() {
    if (_viewModel.curPage == PageType.sync) {
      return const SyncPageFragment();
    } else if (_viewModel.curPage == PageType.library) {
      return libraryListPage();
    } else {
      return const BlankPage();
    }
  }

  /// 文库列表页面
  Widget libraryListPage() {
    if (_viewModel.listEntries.isEmpty) {
      return const BlankPage();
    }

    return Column(
      children: [
        searchLine(),
        Expanded(
          child: Container(
            color: ResColor.bgColor,
            width: double.infinity,
            child: ListView.builder(
              itemCount: _viewModel.listEntries.length,
              itemBuilder: (context, index) {
                final entry = _viewModel.listEntries[index];
                return widgetListEntry(entry);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget searchLine() {
    return Container(
      color: ResColor.bgColor,
      height: 48,
      width: double.infinity,
      child: Row(
        children: [
          Container(width: 20),
          const Icon(Icons.search),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search as you type',
                border: InputBorder.none,
              ),
            ),
          ),
          Container(width: 20),
        ],
      ),
    );
  }

  /// 条目列表
  Widget widgetListEntry(ListEntry entry) {
    return Card(
      elevation: 0,
      color: ResColor.bgColor,
      child: InkWell(
        onTap: () {
          debugPrint("Moyear==== item click");
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: Row(
            children: [
              _entryIcon(entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      child: Text(entry.isCollection() ? entry.collection!.name : entry.item!.getTitle(), maxLines: 2),
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        entry.isItem() ? entry.item!.getAuthor() : "",
                        maxLines: 1,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.isItem() && entry.item!.attachments.isNotEmpty) _attachmentIndicator(entry),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon Widget
  Widget _iconItemWidget(ListEntry entry) {
    if (entry.isCollection()) {
      return SvgPicture.asset(
        'assets/items/opened_folder.svg',
        width: 18,
        height: 18,
        // color: Colors.blue, // 可选颜色
      );
    }

    return requireItemIcon(entry.item?.itemType ?? "");
  }

  /// Entry Icon Widget
  Widget _entryIcon(ListEntry entry) {
    return Container(
      height: 42,
      width: 42,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(26),
      ),
      child: _iconItemWidget(entry),
      // child: ClipRRect(
      //   borderRadius: BorderRadius.circular(20),
      //   child: _iconItemWidget(entry),
      // ),
    );
  }

  Widget _attachmentIndicator(ListEntry entry) {
    return  InkWell(
      onTap: () {
        // print("pdf tap");
      },
      child: Container(
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            "assets/pdf.png",
            width: 20,
            height: 20,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }

  Widget requireItemIcon(String itemType) {
    String iconPath;
    // Assign SVG icon path based on itemType
    switch (itemType) {
      case "note":
        iconPath = 'assets/items/ic_item_note.svg';
        break;
      case "book":
        iconPath = 'assets/items/ic_book.svg';
        break;
      case "bookSection":
        iconPath = 'assets/items/ic_book_section.svg';
        break;
      case "journalArticle":
        iconPath = 'assets/items/journal_article.svg';
        break;
      case "magazineArticle":
        iconPath = 'assets/items/magazine_article_24dp.svg';
        break;
      case "newspaperArticle":
        iconPath = 'assets/items/newspaper_article_24dp.svg';
        break;
      case "thesis":
        iconPath = 'assets/items/ic_thesis.svg';
        break;
      case "letter":
        iconPath = 'assets/items/letter_24dp.svg';
        break;
      case "manuscript":
        iconPath = 'assets/items/manuscript_24dp.svg';
        break;
      case "interview":
        iconPath = 'assets/items/interview_24dp.svg';
        break;
      case "film":
        iconPath = 'assets/items/film_24dp.svg';
        break;
      case "artwork":
        iconPath = 'assets/items/artwork_24dp.svg';
        break;
      case "webpage":
        iconPath = 'assets/items/ic_web_page.svg';
        break;
      case "attachment":
        iconPath = 'assets/items/ic_treeitem_attachment.svg';
        break;
      case "report":
        iconPath = 'assets/items/report_24dp.svg';
        break;
      case "bill":
        iconPath = 'assets/items/bill_24dp.svg';
        break;
      case "case":
        iconPath = 'assets/items/case_24dp.svg';
        break;
      case "hearing":
        iconPath = 'assets/items/hearing_24dp.svg';
        break;
      case "patent":
        iconPath = 'assets/items/patent_24dp.svg';
        break;
      case "statute":
        iconPath = 'assets/items/statute_24dp.svg';
        break;
      case "email":
        iconPath = 'assets/items/email_24dp.svg';
        break;
      case "map":
        iconPath = 'assets/items/map_24dp.svg';
        break;
      case "blogPost":
        iconPath = 'assets/items/blog_post_24dp.svg';
        break;
      case "instantMessage":
        iconPath = 'assets/items/instant_message_24dp.svg';
        break;
      case "forumPost":
        iconPath = 'assets/items/forum_post_24dp.svg';
        break;
      case "audioRecording":
        iconPath = 'assets/items/audio_recording_24dp.svg';
        break;
      case "presentation":
        iconPath = 'assets/items/presentation_24dp.svg';
        break;
      case "videoRecording":
        iconPath = 'assets/items/video_recording_24dp.svg';
        break;
      case "tvBroadcast":
        iconPath = 'assets/items/tv_broadcast_24dp.svg';
        break;
      case "radioBroadcast":
        iconPath = 'assets/items/radio_broadcast_24dp.svg';
        break;
      case "podcast":
        iconPath = 'assets/items/podcast_24dp.svg';
        break;
      case "computerProgram":
        iconPath = 'assets/items/computer_program_24dp.svg';
        break;
      case "conferencePaper":
        iconPath = 'assets/items/ic_conference_paper.svg';
        break;
      case "document":
        iconPath = 'assets/items/ic_document.svg';
        break;
      case "encyclopediaArticle":
        iconPath = 'assets/items/encyclopedia_article_24dp.svg';
        break;
      case "dictionaryEntry":
        iconPath = 'assets/items/dictionary_entry_24dp.svg';
        break;
      default:
        iconPath = 'assets/items/ic_item_known.svg';
    }

    // Return the appropriate SVG image
    return SvgPicture.asset(iconPath, height: 14, width: 14,);
  }


}
