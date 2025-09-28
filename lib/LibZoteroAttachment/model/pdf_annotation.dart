/// PDF注释数据模型
/// 
/// 用于在Flutter和Android之间传递PDF注释信息。
/// 包含注释的基本属性和扩展属性。
/// 
/// 基本属性：
/// - [key]: 注释的唯一标识符
/// - [parentItemKey]: 父级项目的标识符
/// - [pageLabel]: 注释所在的页码
/// - [color]: 注释的颜色
/// - [position]: 注释在页面中的位置信息
/// - [type]: 注释类型（highlight, underline, note, image, text, ink等）
/// 
/// 扩展属性：
/// - [text]: 注释的文本内容
/// - [comment]: 注释的评论内容
/// - [dateAdded]: 添加日期
/// - [dateModified]: 修改日期
/// - [sortIndex]: 排序索引
/// 
/// 使用示例：
/// ```dart
/// final annotation = PdfAnnotation(
///   key: "annotation_123",
///   parentItemKey: "item_456",
///   pageLabel: 1,
///   color: "#FFFF00",
///   position: "{\"rects\":[[100,200,300,400]]}",
///   type: "highlight"
/// );
/// annotation.text = "重要内容";
/// annotation.comment = "这是一个重要的注释";
/// 
/// // 转换为Map用于传递给Android
/// final map = annotation.toMap();
/// 
/// // 从Map创建对象
/// final newAnnotation = PdfAnnotation.fromMap(map);
/// ```
/// 
/// @author ZoteroX Team
/// @since 1.0.0
class PdfAnnotation {
  String key;
  String parentItemKey;
  int pageLabel;
  String color;
  String position;
  String type;

  String text = "";
  String comment = "";
  String dateAdded = "";
  String dateModified = "";
  String sortIndex = "";

  PdfAnnotation({
    required this.key,
    required this.parentItemKey,
    required this.pageLabel,
    required this.color,
    required this.position,
    required this.type,
  });

  /// 将PdfAnnotation对象转换为Map，用于通过MethodChannel传递给Android端
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'parentItemKey': parentItemKey,
      'pageLabel': pageLabel,
      'color': color,
      'position': position,
      'type': type,
      'text': text,
      'comment': comment,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'sortIndex': sortIndex,
    };
  }

  /// 从Map创建PdfAnnotation对象
  factory PdfAnnotation.fromMap(Map<String, dynamic> map) {
    final annotation = PdfAnnotation(
      key: map['key'] ?? '',
      parentItemKey: map['parentItemKey'] ?? '',
      pageLabel: map['pageLabel'] ?? -1,
      color: map['color'] ?? '',
      position: map['position'] ?? '',
      type: map['type'] ?? '',
    );
    
    annotation.text = map['text'] ?? '';
    annotation.comment = map['comment'] ?? '';
    annotation.dateAdded = map['dateAdded'] ?? '';
    annotation.dateModified = map['dateModified'] ?? '';
    annotation.sortIndex = map['sortIndex'] ?? '';
    
    return annotation;
  }

  @override
  String toString() {
    return 'PdfAnnotation{key: $key, parentItemKey: $parentItemKey, pageLabel: $pageLabel, type: $type, text: $text, comment: $comment}';
  }
}
