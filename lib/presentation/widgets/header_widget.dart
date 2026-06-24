import 'dart:io';

import 'package:flutter/material.dart';

class HeaderWidget extends StatefulWidget {
  final String? image;
  final VoidCallback? onTap;

  const HeaderWidget({super.key, this.image, this.onTap});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          widget.image ?? "assets/logo/ic_logo_horizontal.png",
          width: 150,
          height: 50,
        ),
        const Spacer(),

        IconButton(
          icon: const Icon(Icons.speaker_group),
          onPressed: () async {
            widget.onTap;
          },
        ),
      ],
    );
  }
}
