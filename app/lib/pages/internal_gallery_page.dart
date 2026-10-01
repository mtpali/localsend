import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:localsend_app/util/gallery_pager.dart';
import 'package:localsend_app/util/ui/snackbar.dart';
import 'package:localsend_app/widget/static_controls.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_manager/photo_manager.dart';

const _pageSize = 80;
const _thumbnailSize = 192;
const _permissionOptions = PermissionRequestOption(androidPermission: AndroidPermission(type: RequestType.common, mediaLocation: true));

Future<T?> _pushGalleryPage<T>(BuildContext context, Widget page) => Navigator.of(
  context,
).push<T>(PageRouteBuilder<T>(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, _, _) => page));

Future<List<AssetEntity>?> pickInternalGallery(BuildContext context) => _pushGalleryPage(context, const InternalGalleryPage());

/// A lazy internal gallery. Only visible thumbnails are decoded; original
/// files are resolved after confirmation, keeping browsing and selection fast.
class InternalGalleryPage extends StatefulWidget {
  const InternalGalleryPage({super.key});

  @override
  State<InternalGalleryPage> createState() => _InternalGalleryPageState();
}

class _InternalGalleryPageState extends State<InternalGalleryPage> {
  late final _pager = GalleryPager<AssetEntity>(pageSize: _pageSize, onChanged: _rebuild);
  final _scrollController = ScrollController();
  final _selected = <String, AssetEntity>{};
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _album;
  PermissionState? _permission;
  bool _libraryLoading = false;
  bool _libraryFailed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 600 && _pager.error == null) unawaited(_pager.loadNext());
    });
    unawaited(_loadLibrary(requestPermission: true));
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
    // A large tablet can fit an entire page without scrolling. Fill its
    // viewport before waiting for a scroll event to request the next page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          !_pager.isLoading &&
          _pager.hasMore &&
          _pager.error == null &&
          _scrollController.position.extentAfter < 600) {
        unawaited(_pager.loadNext());
      }
    });
  }

  Future<void> _loadLibrary({bool requestPermission = false}) async {
    if (_libraryLoading) return;
    setState(() {
      _libraryLoading = true;
      _libraryFailed = false;
    });
    try {
      final permission = requestPermission
          ? await PhotoManager.requestPermissionExtend(requestOption: _permissionOptions)
          : await PhotoManager.getPermissionState(requestOption: _permissionOptions);
      if (!mounted) return;
      _permission = permission;
      if (!permission.hasAccess) {
        _selected.clear();
        _albums = [];
        _album = null;
        await _pager.reset((_) async => []);
        return;
      }
      final albums = await PhotoManager.getAssetPathList(type: RequestType.common);
      if (!mounted) return;
      _albums = albums;
      final previousId = _album?.id;
      _album = albums.where((p) => p.id == previousId).firstOrNull ?? albums.firstOrNull;
      if (_album == null) {
        await _pager.reset((_) async => []);
      } else {
        await _selectAlbum(_album!);
      }
    } catch (_) {
      if (mounted) _libraryFailed = true;
    } finally {
      if (mounted) {
        _libraryLoading = false;
        _rebuild();
      }
    }
  }

  Future<void> _selectAlbum(AssetPathEntity album) async {
    _album = album;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await _pager.reset((page) => album.getAssetListPaged(page: page, size: _pageSize));
  }

  Future<void> _chooseAlbum() async {
    final album = await showStaticDialog<AssetPathEntity>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Albums'),
        children: [
          SizedBox(
            width: 320,
            height: MediaQuery.sizeOf(dialogContext).height * 0.55,
            child: ListView.builder(
              itemCount: _albums.length,
              itemBuilder: (_, index) {
                final path = _albums[index];
                return ListTile(
                  title: Text(path.isAll ? 'All photos and videos' : path.name),
                  trailing: path.id == _album?.id ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(dialogContext).pop(path),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (album != null && mounted) await _selectAlbum(album);
  }

  void _toggle(AssetEntity asset) {
    if (_selected.containsKey(asset.id)) {
      _selected.remove(asset.id);
    } else if (_selected.length < 999) {
      _selected[asset.id] = asset;
    } else {
      context.showSnackBar('You can select up to 999 items.');
    }
    _rebuild();
  }

  Future<void> _chooseMore() async {
    await PhotoManager.presentLimited(type: RequestType.common);
    if (mounted) await _loadLibrary();
  }

  @override
  void dispose() {
    _pager.dispose();
    _scrollController.dispose();
    _selected.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _pager.items;
    final order = {for (final (index, id) in _selected.keys.indexed) id: index + 1};
    final denied = _permission != null && !_permission!.hasAccess;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos and videos'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.values.toList()),
            child: Text('Done (${_selected.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _albums.isEmpty ? null : _chooseAlbum,
                    icon: const Icon(Icons.folder),
                    label: Text(_album == null || _album!.isAll ? 'All photos and videos' : _album!.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(onPressed: _libraryLoading ? null : _loadLibrary, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          if (_permission == PermissionState.limited) TextButton(onPressed: _chooseMore, child: const Text('Choose more photos and videos')),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _libraryLoading || _pager.isLoading
                              ? 'Loading photos and videos…'
                              : denied
                              ? 'Allow access to photos and videos to use the gallery.'
                              : _libraryFailed || _pager.error != null
                              ? 'Could not load photos and videos.'
                              : 'No photos or videos in this album.',
                          textAlign: TextAlign.center,
                        ),
                        if (denied) TextButton(onPressed: PhotoManager.openSetting, child: const Text('Open settings')),
                        if (_libraryFailed || _pager.error != null) TextButton(onPressed: _loadLibrary, child: const Text('Retry')),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    cacheExtent: 200,
                    addAutomaticKeepAlives: false,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisSpacing: 2, crossAxisSpacing: 2),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final asset = items[index];
                      final selectedOrder = order[asset.id];
                      return Semantics(
                        key: ValueKey(asset.id),
                        button: true,
                        selected: selectedOrder != null,
                        label: '${asset.type == AssetType.video ? 'Video' : 'Photo'} ${index + 1}',
                        child: InkWell(
                          onTap: () => _toggle(asset),
                          onLongPress: () => unawaited(
                            _pushGalleryPage<void>(
                              context,
                              _GalleryPreviewPage(asset: asset, selected: selectedOrder != null, onToggle: () => _toggle(asset)),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _MediaThumbnail(asset: asset),
                              if (asset.type == AssetType.video)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(color: Colors.black, padding: const EdgeInsets.all(2), child: Text(_duration(asset.duration))),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selectedOrder == null ? Colors.black : Colors.white,
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: selectedOrder == null ? null : Text('$selectedOrder', style: const TextStyle(color: Colors.black)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_pager.isLoading && items.isNotEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Loading…')),
          if (_pager.error != null && items.isNotEmpty) TextButton(onPressed: _pager.loadNext, child: const Text('Retry loading more')),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Tap to select · Hold to preview', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

String _duration(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class _MediaThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final int size;

  const _MediaThumbnail({required this.asset, this.size = _thumbnailSize});

  @override
  State<_MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<_MediaThumbnail> {
  final _cancelToken = PMCancelToken();
  late final _thumbnail = widget.asset.thumbnailDataWithSize(ThumbnailSize.square(widget.size), quality: 75, cancelToken: _cancelToken);

  @override
  void dispose() {
    unawaited(_cancelToken.cancelRequest().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _thumbnail,
    builder: (_, snapshot) => snapshot.data == null
        ? const Center(child: Icon(Icons.image))
        : Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            cacheWidth: widget.size,
            cacheHeight: widget.size,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
          ),
  );
}

class _GalleryPreviewPage extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  final VoidCallback onToggle;

  const _GalleryPreviewPage({required this.asset, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Preview'),
      actions: [
        TextButton(
          onPressed: () {
            onToggle();
            Navigator.of(context).pop();
          },
          child: Text(selected ? 'Remove' : 'Select'),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: Center(child: _PreviewImage(asset: asset)),
        ),
        if (asset.type == AssetType.video)
          TextButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play video'),
            onPressed: () async {
              try {
                final file = await asset.originFile;
                if (file == null) throw StateError('Video unavailable');
                final result = await OpenFilex.open(file.path);
                if (result.type != ResultType.done && context.mounted) context.showSnackBar(result.message);
              } catch (_) {
                if (context.mounted) context.showSnackBar('Could not open video.');
              }
            },
          ),
      ],
    ),
  );
}

class _PreviewImage extends StatefulWidget {
  final AssetEntity asset;
  const _PreviewImage({required this.asset});

  @override
  State<_PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<_PreviewImage> {
  final _cancelToken = PMCancelToken();
  late final _data = widget.asset.thumbnailDataWithSize(const ThumbnailSize.square(1024), quality: 85, cancelToken: _cancelToken);

  @override
  void dispose() {
    unawaited(_cancelToken.cancelRequest().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _data,
    builder: (_, snapshot) => snapshot.data == null
        ? Text(snapshot.hasError || snapshot.connectionState == ConnectionState.done ? 'Could not load preview.' : 'Loading preview…')
        : Image.memory(snapshot.data!, fit: BoxFit.contain, cacheWidth: 1024),
  );
}
