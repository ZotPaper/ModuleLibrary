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
}
