part of 'image_cubit.dart';

@immutable
abstract class ImageState {}

class ImageInitial extends ImageState {}

class ImageUploading extends ImageState {}

class ImagePicked extends ImageState {
  final XFile image;
  ImagePicked(this.image);
}

class ImageUploaded extends ImageState {
  final String response;
  ImageUploaded(this.response);
}

class ImageError extends ImageState {
  final String message;
  ImageError(this.message);
}
