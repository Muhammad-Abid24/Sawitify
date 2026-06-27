import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawitify/data/model/album_model.dart';

import '../../core/network/api_client.dart';
import '../../core/network/response/home_response.dart';
import '../../data/repository/home_repository.dart';

class AllPlaylistPage extends StatefulWidget {
  final String title;
  final List<Album>? items;

  const AllPlaylistPage({super.key, required this.title, required this.items});

  @override
  State<AllPlaylistPage> createState() => _AllPlaylistPage();
}

class _AllPlaylistPage extends State<AllPlaylistPage> {
  List<Shelf> shelves = [];

  bool isLoading = true;

  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
                  //child: _buildHeader(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
                  //child: _buildHeader(),
                ),
              ),
              Center(child: Text(errorMessage!)),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Background color fills entire screen
          Container(color: Colors.black),

          // Fixed Header (not scrollable)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
              //child: _buildHeader(),
            ),
          ),

          // Scrollable content - starts below header, extends behind navbar
          Padding(
            padding: const EdgeInsets.only(top: 110),

            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await loadHome();
                    //await loadConcert1();
                  },

                  child: CustomScrollView(
                    //controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),

                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          //child: _buildCategories(),
                        ),
                      ),

                      //_buildContent(),
                      const SliverToBoxAdapter(child: SizedBox(height: 150)),
                    ],
                  ),
                ),

                // Positioned(
                //   right: 0,
                //
                //   top: 20,
                //
                //   bottom: 160,
                //
                //   child: IgnorePointer(
                //     child: AnimatedOpacity(
                //       //opacity: _showScrollbar ? 1 : 0,
                //
                //       duration: const Duration(milliseconds: 250),
                //
                //       child: Align(
                //         //alignment: Alignment(1, -1 + (_scrollProgress * 2)),
                //
                //         child: Container(
                //           width: 5,
                //
                //           height: 55,
                //
                //           decoration: BoxDecoration(
                //             color: AppColors.primary,
                //
                //             borderRadius: BorderRadius.circular(999),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadHome() async {
    try {
      final repository = HomeRepository(ApiClient().dioBrowse);

      final response = await repository.getHome();

      debugPrint('================ HOME =================');
      debugPrint('HOME SHELVES : ${response.shelves.length}');

      for (final shelf in response.shelves) {
        debugPrint(
          'HOME => "${shelf.title}" '
          'items=${shelf.items.length}',
        );
      }

      final more1 = await repository.load1(
        '4qmFsgKhAhIMRkVtdXNpY19ob21lGpACQ0FONnh3RkhUVmh2TURoZmF5MUtVVVJYYjBWQ1EyNDRTMHBJYkRCWU0wSm9XakpXWm1NeU5XaGpTRTV2WWpOU1ptSllWbnBoVjA1bVkwZEdibHBXT1hsYVYyUndZakkxYUdKQ1NXWlZWRVl6VkVkc1ptVnNSbkJsVlVaVlVWVlNSR0pZV25oalZtaHFXVzVHZEZWSFNqVlhWRnB2WVhodk1sUllWbnBoVjA1RllWaE9hbUl6V214amJteFJXVmRrYkZVeVZubGtiV3hxV2xNeFNGcFlVa2xpTWpGc1ZVZEdibHBSUVVKQlIyeHJRVUZHU2xKQlFVSlRWVkZCUVZGRlJDMXdla2gyVVd0RFEwRlI=',
      );

      final more2 = await repository.load2(
        '4qmFsgKhAhIMRkVtdXNpY19ob21lGpACQ0FaNnh3RkhTV0Z6ZGs5MVpHaHdWVVJYYjBWQ1EyNDRTMHBJYkRCWU0wSm9XakpXWm1NeU5XaGpTRTV2WWpOU1ptSllWbnBoVjA1bVkwZEdibHBXT1hsYVYyUndZakkxYUdKQ1NXWlJWRlY0WVVSc2FsVkVTbHBrVlZadFVWVlNSR0pZV25oalZtaHFXVzA0ZVU5R1dYaFZhbVJEWVhodk1sUllWbnBoVjA1RllWaE9hbUl6V214amJteFJXVmRrYkZVeVZubGtiV3hxV2xNeFNGcFlVa2xpTWpGc1ZVZEdibHBSUVVKQlIyeHJRVUZHU2xKQlFVSlRWVkZCUVZGRlJDMXdla2gyVVd0RFEwRmo=',
      );

      debugPrint('============= CONTINUATION 1 =============');
      debugPrint('CONTINUATION SHELVES 1 : ${more1.shelves.length}');
      debugPrint('============= CONTINUATION 2 =============');
      debugPrint('CONTINUATION SHELVES 2 : ${more2.shelves.length}');

      for (final shelf in more1.shelves) {
        debugPrint(
          'CONTINUATION 1 => "${shelf.title}" '
          'items=${shelf.items.length}',
        );
      }
      for (final shelf in more2.shelves) {
        debugPrint(
          'CONTINUATION 2 => "${shelf.title}" '
          'items=${shelf.items.length}',
        );
      }

      final allShelves = [
        ...response.shelves,
        ...more1.shelves,
        ...more2.shelves,
      ];

      debugPrint('HOME COUNT = ${response.shelves.length}');

      debugPrint('MORE COUNT = ${more1.shelves.length}');

      debugPrint('ALL COUNT = ${allShelves.length}');

      for (int i = 0; i < allShelves.length; i++) {
        debugPrint(
          '[$i] ${allShelves[i].title} (${allShelves[i].items.length})',
        );
      }

      if (!mounted) return;

      debugPrint('TOTAL SHELVES : ${allShelves.length}');

      for (final shelf in allShelves) {
        debugPrint('SHELF => ${shelf.title} (${shelf.items.length} items)');

        for (final album in shelf.items.take(5)) {
          debugPrint('   • ${album.title} | ${album.subtitle}');
        }
      }

      setState(() {
        shelves = allShelves.where((shelf) {
          // Skip jika playlist kosong
          if (shelf.items.isEmpty) {
            return false;
          }

          return true;
        }).toList();

        isLoading = false;
      });
    } catch (e, s) {
      debugPrint("ERROR : $e");
      debugPrint(s.toString());

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
}
