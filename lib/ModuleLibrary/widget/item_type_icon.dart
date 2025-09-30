import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';

/// 条目类型图标组件
/// 
/// 根据Zotero条目类型显示对应的SVG图标
/// 支持所有Zotero条目类型，包括文献、书籍、网页、附件等
class ItemTypeIcon extends StatelessWidget {
  final String itemType;
  final double size;
  final Color? color;

  const ItemTypeIcon({
    super.key,
    required this.itemType,
    this.size = 14,
    this.color,
  });

  /// 根据itemType创建图标
  factory ItemTypeIcon.fromItemType({
    required String itemType,
    double size = 14,
    Color? color,
  }) {
    return ItemTypeIcon(
      itemType: itemType,
      size: size,
      color: color,
    );
  }

  /// 文件夹图标
  factory ItemTypeIcon.folder({
    double size = 14,
    Color? color,
  }) {
    return ItemTypeIcon(
      itemType: '_folder',
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _getIconPath(itemType);
    
    // 文件夹图标不需要颜色滤镜
    if (itemType == '_folder') {
      return SvgPicture.asset(
        iconPath,
        package: 'module_library',
        width: size,
        height: size,
      );
    }

    return SvgPicture.asset(
      iconPath,
      height: size,
      width: size,
      package: 'module_library',
      colorFilter: ColorFilter.mode(
        color ?? ResColor.textMain,
        BlendMode.srcIn,
      ),
    );
  }

  /// 根据条目类型获取图标路径
  String _getIconPath(String itemType) {
    switch (itemType) {
      case '_folder':
        return 'assets/items/opened_folder.svg';
      case "note":
        return 'assets/items/ic_item_note.svg';
      case "book":
        return 'assets/items/ic_book.svg';
      case "bookSection":
        return 'assets/items/ic_book_section.svg';
      case "journalArticle":
        return 'assets/items/journal_article.svg';
      case "magazineArticle":
        return 'assets/items/magazine_article_24dp.svg';
      case "newspaperArticle":
        return 'assets/items/newspaper_article_24dp.svg';
      case "thesis":
        return 'assets/items/ic_thesis.svg';
      case "letter":
        return 'assets/items/letter_24dp.svg';
      case "manuscript":
        return 'assets/items/manuscript_24dp.svg';
      case "interview":
        return 'assets/items/interview_24dp.svg';
      case "film":
        return 'assets/items/film_24dp.svg';
      case "artwork":
        return 'assets/items/artwork_24dp.svg';
      case "webpage":
        return 'assets/items/ic_web_page.svg';
      case "attachment":
        return 'assets/items/ic_treeitem_attachment.svg';
      case "report":
        return 'assets/items/report_24dp.svg';
      case "bill":
        return 'assets/items/bill_24dp.svg';
      case "case":
        return 'assets/items/case_24dp.svg';
      case "hearing":
        return 'assets/items/hearing_24dp.svg';
      case "patent":
        return 'assets/items/patent_24dp.svg';
      case "statute":
        return 'assets/items/statute_24dp.svg';
      case "email":
        return 'assets/items/email_24dp.svg';
      case "map":
        return 'assets/items/map_24dp.svg';
      case "blogPost":
        return 'assets/items/blog_post_24dp.svg';
      case "instantMessage":
        return 'assets/items/instant_message_24dp.svg';
      case "forumPost":
        return 'assets/items/forum_post_24dp.svg';
      case "audioRecording":
        return 'assets/items/audio_recording_24dp.svg';
      case "presentation":
        return 'assets/items/presentation_24dp.svg';
      case "videoRecording":
        return 'assets/items/video_recording_24dp.svg';
      case "tvBroadcast":
        return 'assets/items/tv_broadcast_24dp.svg';
      case "radioBroadcast":
        return 'assets/items/radio_broadcast_24dp.svg';
      case "podcast":
        return 'assets/items/podcast_24dp.svg';
      case "computerProgram":
        return 'assets/items/computer_program_24dp.svg';
      case "conferencePaper":
        return 'assets/items/ic_conference_paper.svg';
      case "document":
        return 'assets/items/ic_document.svg';
      case "encyclopediaArticle":
        return 'assets/items/encyclopedia_article_24dp.svg';
      case "dictionaryEntry":
        return 'assets/items/dictionary_entry_24dp.svg';
      default:
        return 'assets/items/ic_item_known.svg';
    }
  }
} 