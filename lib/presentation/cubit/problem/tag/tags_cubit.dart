import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../data/models/tag.dart';

part 'tags_state.dart';

class TagsCubit extends Cubit<TagsState> {
  final ApiService apiService;

  TagsCubit(this.apiService) : super(TagsInitial());

  Future<void> fetchTags() async {
    emit(TagsLoading());
    try {
      final tags = await apiService.getTags();
      emit(TagsLoaded(tags));
    } catch (e) {
      emit(TagsError('Failed to load tags'));
    }
  }
}
