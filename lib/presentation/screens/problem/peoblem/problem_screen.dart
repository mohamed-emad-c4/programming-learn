import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../data/models/problem_model.dart';
import '../../../cubit/problem/problem/problem_cubit.dart';
import '../../../cubit/problem/problem/problem_state.dart';

class ProblemScreen extends StatefulWidget {
  final int tagId;
  const ProblemScreen({super.key, required this.tagId});

  @override
  State<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen> {
  List<ProblemModel> _filteredProblems = [];
  bool isAscending = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProblemCubit(ApiService())..fetchProblemsByTag(widget.tagId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Problems',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  isAscending = !isAscending;
                  _sortProblems();
                });
              },
            ),
          ],
        ),
        body: BlocBuilder<ProblemCubit, ProblemState>(
          builder: (context, state) {
            if (state is ProblemLoading) {
              return _buildShimmerLoading();
            } else if (state is ProblemLoaded) {
              _filteredProblems = state.problems;
              _sortProblems();
              return _filteredProblems.isNotEmpty
                  ? _buildProblemList(_filteredProblems)
                  : _buildEmptyState();
            } else if (state is ProblemError) {
              return _buildErrorState(context, state.message);
            } else {
              return const Center(child: Text('Something went wrong.'));
            }
          },
        ),
      ),
    );
  }

  void _sortProblems() {
    if (isAscending) {
      _filteredProblems.sort((a, b) => a.level.compareTo(b.level));
    } else {
      _filteredProblems.sort((a, b) => b.level.compareTo(a.level));
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const ListTile(
            title: Text('Loading...'),
            subtitle: Text('Please wait'),
            leading: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildProblemList(List<ProblemModel> problems) {
    return ListView.builder(
      itemCount: problems.length,
      itemBuilder: (context, index) {
        final problem = problems[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/solve_problem',
                  arguments: problem.id,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      problem.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            'Level ${problem.level}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getLevelColor(problem.level),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/solve_problem',
                              arguments: problem.id,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Solve',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'No Problems Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Try searching for something else.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 80, color: Colors.redAccent),
          const SizedBox(height: 20),
          Text(
            'Error: $message',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              context.read<ProblemCubit>().fetchProblemsByTag(widget.tagId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}