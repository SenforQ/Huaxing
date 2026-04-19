import 'package:flutter/material.dart';

class LensNetworkOrAssetImage extends StatelessWidget {
  const LensNetworkOrAssetImage({
    super.key,
    required this.imageRef,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String imageRef;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  static bool isAsset(String ref) => ref.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final ImageErrorWidgetBuilder err = errorBuilder ?? _defaultError;
    if (isAsset(imageRef)) {
      return Image.asset(
        imageRef,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: err,
      );
    }
    return Image.network(
      imageRef,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: loadingBuilder,
      errorBuilder: err,
    );
  }

  Widget _defaultError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.white.withOpacity(0.06),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white38,
        size: 48,
      ),
    );
  }
}
