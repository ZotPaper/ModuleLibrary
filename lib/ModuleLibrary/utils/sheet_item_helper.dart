class ItemClickProxy {

  /// 标题文字
  String title;

  /// 辅助信息
  String? desc;

  /// 样式
  String? actionStyle;

  Function? onClick;

  ItemClickProxy({
    required this.title,
    this.desc,
    this.actionStyle = "normal",
    this.onClick,
  });

}