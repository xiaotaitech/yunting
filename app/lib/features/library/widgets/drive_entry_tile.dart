import 'package:flutter/material.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/media_files.dart';
import 'package:yun_audiobook/features/common/format.dart';

class DriveEntryTile extends StatelessWidget {
  const DriveEntryTile({
    required this.entry,
    required this.onOpenFolder,
    super.key,
  });

  final DriveEntry entry;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final isAudio = isMediaEntry(entry);
    return ListTile(
      leading: Icon(
        entry.isDirectory
            ? Icons.folder
            : isAudio
                ? Icons.audiotrack
                : Icons.insert_drive_file_outlined,
      ),
      title: Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: entry.isDirectory ? null : Text(formatBytes(entry.size)),
      trailing: entry.isDirectory ? const Icon(Icons.chevron_right) : null,
      enabled: entry.isDirectory || isAudio,
      onTap: entry.isDirectory ? onOpenFolder : null,
    );
  }
}
