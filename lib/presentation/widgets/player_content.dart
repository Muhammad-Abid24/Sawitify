import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sawitify/presentation/widgets/player_info.dart';

import '../../core/theme/app_theme.dart';

class PlayerContent extends StatelessWidget {
  const PlayerContent({super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.duration,
    required this.videoId,
    required this.controller,
  });

  final String imageUrl;
  final String title;
  final String artist;
  final String duration;
  final String videoId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.sizeOf(context);

    final isTablet = size.width >= 700;

    final artworkHeight = isTablet
        ? size.height * 0.55
        : size.height * 0.50;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        slivers: [

          SliverToBoxAdapter(
            child: SizedBox(
              height: artworkHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.0),
                          Colors.black.withOpacity(.1),
                          Colors.black.withOpacity(.6),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 60),
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                          BorderRadius.circular(200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 24,
              ),
              child: MusicInfoSection(
                title: title,
                artist: artist,
                videoId: videoId),
            ),
          ),
        ],
      ),
    );
  }
}