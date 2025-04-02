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
          backgroundColor: Colors.blue.shade800,
          title: const Text('Tags ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              )),
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildTagList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Tags...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: searchQuery.isEmpty
                  ? Icon(Icons.search, color: Colors.indigo.shade300)
                  : Icon(Icons.search, color: Colors.indigo),
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _buildTagList() {
    return BlocBuilder<TagsCubit, TagsState>(
      builder: (context, state) {
        if (state is TagsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TagsLoaded) {
          final filteredTags = state.tags
              .where((tag) => tag.name.toLowerCase().contains(searchQuery))
              .toList();

          if (filteredTags.isEmpty) {
            return const Center(
              child: Text(
                'No tags found. Try a different search!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TagsCubit>().fetchTags();
            },
            child: AnimationLimiter(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                itemCount: filteredTags.length,
                itemBuilder: (context, index) {
                  final tag = filteredTags[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            log(tag.id.toString());
                            Navigator.pushNamed(context, '/problems',
                                arguments: tag.id);
                          },
                          child: _buildTagCard(tag),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (state is TagsError) {
          return _buildErrorState();
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildTagCard(tag) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 9,
      shadowColor: Colors.indigo.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            _buildTagImage(tag),
            const SizedBox(width: 15),
            _buildTagDetails(tag),
          ],
        ),
      ),
    );
  }

  Widget _buildTagImage(tag) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: CachedNetworkImage(
          imageUrl: tag.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTagDetails(tag) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.name,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            tag.description,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Failed to load tags',
              style: TextStyle(fontSize: 18, color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              context.read<TagsCubit>().fetchTags();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      ),
    );
  }
}
