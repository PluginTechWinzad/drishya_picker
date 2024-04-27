import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drishya_picker/drishya_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget to display [DrishyaEntity] thumbnail
class EntityThumbnail extends StatelessWidget {
  ///
  const EntityThumbnail({
    Key? key,
    required this.entity,
    this.onBytesGenerated,
  }) : super(key: key);

  ///
  final DrishyaEntity entity;

  /// Callback function triggered when image bytes is generated
  final ValueSetter<Uint8List?>? onBytesGenerated;

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox();

    //
    if (entity.type == AssetType.image || entity.type == AssetType.video) {
      return FutureBuilder<Uint8List?>(
        future: entity.thumbnailDataWithOption(
          ThumbnailOption.ios(
            size: const ThumbnailSize.square(500),
            resizeContentMode: ResizeContentMode.fill,
          ),
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          Widget w;
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else if (snapshot.hasData) {
            final Uint8List data = snapshot.data!;
            ui.decodeImageFromList(data, (ui.Image result) {
              // for 4288x2848
            });
            w = Image.memory(data,fit: BoxFit.cover,);
          } else {
            w = Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: const CircularProgressIndicator(),
              ),
            );
          }
          return GestureDetector(
            child: w,
            onTap: () => Navigator.pop(context),
          );
        },
      );
    }

    if (entity.type == AssetType.audio) {
      child = const Center(child: Icon(Icons.audiotrack, color: Colors.white));
    }

    if (entity.type == AssetType.other) {
      child = const Center(child: Icon(Icons.file_copy, color: Colors.white));
    }

    if (entity.type == AssetType.video || entity.type == AssetType.audio) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          child,
          Align(
            alignment: Alignment.bottomRight,
            child: _DurationView(duration: entity.duration),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: child,
    );
  }
}

/// ImageProvider implementation
@immutable
class _MediaThumbnailProvider extends ImageProvider<_MediaThumbnailProvider> {
  /// Constructor for creating a [_MediaThumbnailProvider]
  const _MediaThumbnailProvider({
    required this.entity,
    this.onBytesLoaded,
  });

  ///
  final DrishyaEntity entity;
  final ValueSetter<Uint8List?>? onBytesLoaded;

  @override
  ImageStreamCompleter load(
    _MediaThumbnailProvider key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _loadAsync(key, decode),
        scale: 1,
        informationCollector: () sync* {
          yield ErrorDescription('Id: ${entity.id}');
        },
      );

  Future<ui.Codec> _loadAsync(
    _MediaThumbnailProvider key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this, 'Checks _MediaThumbnailProvider');
    final bytes = entity.pickedThumbData;
    onBytesLoaded?.call(bytes);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes!);
    return decode(buffer);
  }

  @override
  Future<_MediaThumbnailProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_MediaThumbnailProvider>(this);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    // ignore: test_types_in_equals
    final typedOther = other as _MediaThumbnailProvider;
    return entity.id == typedOther.entity.id;
  }

  @override
  int get hashCode => entity.id.hashCode;

  @override
  String toString() => '$_MediaThumbnailProvider("${entity.id}")';
}

class _DurationView extends StatelessWidget {
  const _DurationView({
    Key? key,
    required this.duration,
  }) : super(key: key);

  final int duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.7),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          duration.formatedDuration,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

extension on int {
  String get formatedDuration {
    final duration = Duration(seconds: this);
    final min = duration.inMinutes.remainder(60).toString().padRight(2, '0');
    final sec = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
