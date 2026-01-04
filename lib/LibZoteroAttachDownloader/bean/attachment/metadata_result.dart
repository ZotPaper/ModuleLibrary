import '../network/general_result.dart';

abstract class MetadataResult extends CustomResult {
  const MetadataResult();
}

class Unchanged extends MetadataResult {
  const Unchanged();
}

class MtimeChanged extends MetadataResult {
  final int mtime;

  const MtimeChanged(this.mtime);
}

class Changed extends MetadataResult {
  final String url;

  const Changed(this.url);
}

class New extends MetadataResult {
  final String url;

  const New(this.url);
}