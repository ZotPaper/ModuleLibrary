import 'dart:io';

sealed class AttachmentUploadResult {
  const AttachmentUploadResult();

  const factory AttachmentUploadResult.exists() = UploadResultExists;
  const factory AttachmentUploadResult.newResult(String url, File file) = UploadResultNew;
}

class UploadResultExists extends AttachmentUploadResult {
  const UploadResultExists();
}

class UploadResultNew extends AttachmentUploadResult {
  final String url;
  final File file;

  const UploadResultNew(this.url, this.file);
}