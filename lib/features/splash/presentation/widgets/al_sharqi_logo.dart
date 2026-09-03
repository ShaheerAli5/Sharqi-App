import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';

class AlSharqiLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const AlSharqiLogo({
    super.key,
    this.width = 200,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logoPng,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
