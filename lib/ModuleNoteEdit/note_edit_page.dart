import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:module_library/LibZoteroStorage/entity/Note.dart';

class NoteEditPage extends StatefulWidget {
  final Note note;

  const NoteEditPage(this.note, {super.key});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('查看笔记'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        // actions: [
        //   // 可以添加编辑、分享等功能按钮
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () {
        //       // TODO: 实现编辑笔记功能
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('编辑功能待开发')),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 笔记元数据信息
              if (widget.note.version > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '版本: ${widget.note.version}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.note.tags.isNotEmpty) ...[
                        const Icon(Icons.label_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.note.tags.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              
              // // 分隔线
              // if (widget.note.version > 0)
              //   Divider(color: Colors.grey[300]),
              
              const SizedBox(height: 8),
              
              // 笔记内容 - 使用 HTML 渲染
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  // side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Html(
                    data: widget.note.note,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      "h1": Style(
                        fontSize: FontSize(24),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 16, bottom: 8),
                      ),
                      "h2": Style(
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 12, bottom: 6),
                      ),
                      "h3": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 10, bottom: 5),
                      ),
                      "ul": Style(
                        margin: Margins.only(left: 16, bottom: 8),
                      ),
                      "ol": Style(
                        margin: Margins.only(left: 16, bottom: 8),
                      ),
                      "li": Style(
                        margin: Margins.only(bottom: 4),
                      ),
                      "blockquote": Style(
                        border: const Border(
                          left: BorderSide(color: Colors.grey, width: 4),
                        ),
                        margin: Margins.symmetric(vertical: 8),
                        padding: HtmlPaddings.only(left: 16),
                        fontStyle: FontStyle.italic,
                      ),
                      "code": Style(
                        backgroundColor: Colors.grey[200],
                        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                        fontFamily: 'monospace',
                      ),
                      "pre": Style(
                        backgroundColor: Colors.grey[200],
                        padding: HtmlPaddings.all(12),
                        margin: Margins.symmetric(vertical: 8),
                        fontFamily: 'monospace',
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}