

class ItemLockedException implements Exception  {
  final String message;
  final int errorCode;
  ItemLockedException(this.message, this.errorCode);
}

class ItemChangedSinceException implements Exception  {
  final String message;
  final int errorCode;
  ItemChangedSinceException(this.message, this.errorCode);
}