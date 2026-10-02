import 'package:dart_mappable/dart_mappable.dart';
import 'package:intl/intl.dart';
import 'package:localsend_isolates/model/file_type.dart';

part 'receive_history_entry.mapper.dart';

@MappableClass()
class ReceiveHistoryEntry with ReceiveHistoryEntryMappable {
  final String id;

  /// The name of the file.
  /// If [isMessage] is true, this is the message content.
  final String fileName;

  final FileType fileType;
  final String? path;
  final bool savedToGallery;

  @MappableField(hook: IsMessageHook())
  final bool isMessage;

  final int fileSize;
  final String senderAlias;
  final DateTime timestamp;

  const ReceiveHistoryEntry({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.path,
    required this.savedToGallery,
    required this.isMessage,
    required this.fileSize,
    required this.senderAlias,
    required this.timestamp,
  });

  /// Format string using the intl package.
  /// Because the raw timestamp is saved in UTC, we need to transform it to local time zone first.
  String get timestampString {
    final localTimestamp = timestamp.toLocal();
    // intl ships en_US data by default. The language-only "en" locale needs
    // initialization, which the English-only app no longer performs.
    return '${DateFormat.yMd('en_US').format(localTimestamp)} ${DateFormat.jm('en_US').format(localTimestamp)}';
  }

  static const fromJson = ReceiveHistoryEntryMapper.fromJson;
}

class IsMessageHook extends MappingHook {
  const IsMessageHook();

  @override
  Object? beforeDecode(Object? value) {
    return value == true;
  }
}
