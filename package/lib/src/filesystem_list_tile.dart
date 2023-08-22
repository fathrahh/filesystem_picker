import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'common.dart';
import 'options/theme/_filelist_theme.dart';

/// A single row displaying a folder or file, the corresponding icon and the trailing
/// selection button for the file (configured in the `fileTileSelectMode` parameter).
///
/// Used in conjunction with the `FilesystemList` widget.
class FilesystemListTile extends StatefulWidget {
  /// The type of view (folder and files, folder only or files only), by default `FilesystemType.all`.
  final FilesystemType fsType;

  /// The entity of the file system that should be displayed by the widget.
  final FileSystemEntity item;

  /// The color of the folder icon in the list.
  final Color? folderIconColor;

  /// Called when the user has touched a subfolder list item.
  final ValueChanged<Directory> onChange;

  /// Called when a file system item is selected.
  final ValueSelected onSelect;

  /// Specifies how to files can be selected (either tapping on the whole tile or only on trailing button).
  final FileTileSelectMode fileTileSelectMode;

  /// Specifies a list theme in which colors, fonts, icons, etc. can be customized.
  final FilesystemPickerFileListThemeData? theme;

  /// Specifies the extension comparison mode to determine the icon specified for the file types in the theme,
  /// case-sensitive or case-insensitive, by default it is insensitive.
  final bool caseSensitiveFileExtensionComparison;

  /// Creates a file system entity list tile.
  FilesystemListTile({
    Key? key,
    this.fsType = FilesystemType.all,
    required this.item,
    this.folderIconColor,
    required this.onChange,
    required this.onSelect,
    required this.fileTileSelectMode,
    this.theme,
    this.caseSensitiveFileExtensionComparison = false,
  }) : super(key: key);

  @override
  State<FilesystemListTile> createState() => _FilesystemListTileState();
}

class _FilesystemListTileState extends State<FilesystemListTile> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _leading(BuildContext context, FilesystemPickerFileListThemeData theme,
      bool isFile) {
    if (widget.item is Directory) {
      return Icon(
        theme.getFolderIcon(context),
        color: theme.getFolderIconColor(context, widget.folderIconColor),
        size: theme.getIconSize(context),
      );
    } else {
      return _fileIcon(context, theme, widget.item.path, isFile);
    }
  }

  /// Set the icon for a file
  Icon _fileIcon(BuildContext context, FilesystemPickerFileListThemeData theme,
      String filename, bool isFile,
      [Color? color]) {
    final _extension = filename.split(".").last;
    IconData icon = theme.getFileIcon(
        context, _extension, widget.caseSensitiveFileExtensionComparison);

    return Icon(
      icon,
      color: theme.getFileIconColor(context, color),
      size: theme.getIconSize(context),
    );
  }

  Widget? _trailing(BuildContext context,
      FilesystemPickerFileListThemeData theme, bool isFile) {
    final isCheckable = ((widget.fsType == FilesystemType.all) ||
        ((widget.fsType == FilesystemType.file) &&
            (widget.item is File) &&
            (widget.fileTileSelectMode != FileTileSelectMode.wholeTile)));

    if (isCheckable) {
      final iconTheme = theme.getCheckIconTheme(context);
      return InkResponse(
        child: Icon(
          theme.getCheckIcon(context),
          color: iconTheme.color,
          size: iconTheme.size,
        ),
        onTap: () => widget.onSelect(widget.item.absolute.path),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? FilesystemPickerFileListThemeData();
    final isFile =
        (widget.fsType == FilesystemType.file) && (widget.item is File);
    final style = !isFile
        ? effectiveTheme.getFolderTextStyle(context)
        : effectiveTheme.getFileTextStyle(context);

    void Function()? onTap = (widget.item is Directory)
        ? () => widget.onChange(widget.item as Directory)
        : ((widget.fsType == FilesystemType.file &&
                widget.fileTileSelectMode == FileTileSelectMode.wholeTile)
            ? () => widget.onSelect(widget.item.absolute.path)
            : null);

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
          RawKeyEventDataAndroid rawKeyEventDataAndroid =
              event.data as RawKeyEventDataAndroid;
          if (rawKeyEventDataAndroid == 23 && onTap != null) {
            onTap();
          }
        }
      },
      child: ListTile(
        key: Key(widget.item.absolute.path),
        leading: _leading(context, effectiveTheme, isFile),
        trailing: _trailing(context, effectiveTheme, isFile),
        title: Text(Path.basename(widget.item.path),
            style: style,
            textScaleFactor:
                effectiveTheme.getTextScaleFactor(context, isFile)),
        onTap: onTap,
      ),
    );
  }
}
