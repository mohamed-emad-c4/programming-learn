import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../cubit/problem/tag/tags_cubit.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TagsCubit(ApiService())..fetchTags(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tags Preview'),
          // backgroundColor: Colors.teal,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Material(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Tags...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: searchQuery.isEmpty
                          ? Icon(Icons.search, color: Colors.teal.shade300)
                          : Icon(Icons.search, color: Colors.teal),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.close, color: Colors.grey.shade600),
                            onPressed: () {
                              setState(() {
                                _searchController
                                    .clear(); // Clears the TextField
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<TagsCubit, TagsState>(
                builder: (context, state) {
                  if (state is TagsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TagsLoaded) {
                    // Filtered Tags
                    final filteredTags = state.tags
                        .where((tag) =>
                            tag.name.toLowerCase().contains(searchQuery))
                        .toList();

                    // Empty State
                    if (filteredTags.isEmpty) {
                      return const Center(
                        child: Text(
                          'No tags found. Try a different search!',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    // Pull-to-Refresh and Animated List
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<TagsCubit>().fetchTags();
                      },
                      child: AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 10),
                          itemCount: filteredTags.length,
                          itemBuilder: (context, index) {
                            final tag = filteredTags[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                       log(tag.id.toString());
                                       Navigator.pushNamed(context, '/problems', arguments: tag.id);

                                      },
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 4,
                                        shadowColor:
                                            Colors.black.withOpacity(0.2),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Row(
                                            children: [
                                              // Display Image with Border
                                              Container(
                                                padding: const EdgeInsets.all(
                                                    4), // Space for border
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  border: Border.all(
                                                    color: Colors.teal.shade300,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50), // Circular Image
                                                  child: CachedNetworkImage(
                                                    imageUrl: tag.imageUrl,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            const SizedBox(
                                                      width: 60,
                                                      height: 60,
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const CircleAvatar(
                                                      radius: 30,
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              // Text Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tag.name,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      tag.description,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } else if (state is TagsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Failed to load tags',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<TagsCubit>().fetchTags();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('No data available'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
