import 'package:flutter/material.dart';
import 'sivanya_loader.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final String? message;
  final Color? backgroundColor;

  const LoadingWidget({
    super.key,
    this.size = 56,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SivanyaLoader(
      size: size,
      message: message,
      backgroundColor: backgroundColor,
    );
  }
}
