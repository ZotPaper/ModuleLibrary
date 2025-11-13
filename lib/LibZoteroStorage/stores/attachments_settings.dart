import 'package:module_base/utils/store/iface.dart';

class AttachmentStore extends HiveStore {
  AttachmentStore() : super('attachment');

  late final useWebDAV = const PrefPropDefault('use_webdav', false);

  late final uploadAttachmentEnable = const PrefPropDefault('attachments_uploading_enabled', true);

  late final allInsecureSSL = const PrefPropDefault('webdav_allowInsecureSSL', false);

  late final webdavAddress = const PrefPropDefault('webdav_address', "");

  PrefPropDefault<String> webdavUsername = const PrefPropDefault('webdav_username', "");

  PrefPropDefault<String> webdavPassword = const PrefPropDefault('webdav_password', "");

  late final useExternalPdfReader = const PrefPropDefault('use_external_pdf_reader', false);

}

