import 'package:chopper/chopper.dart';

part 'sake_menu_recognition_api_client.chopper.dart';

@ChopperApi(baseUrl: '/api/menu-recognition')
abstract class SakeMenuRecognitionApiClient extends ChopperService {
  static SakeMenuRecognitionApiClient create([ChopperClient? client]) =>
      _$SakeMenuRecognitionApiClient(client);

  @Post(path: 'recognize')
  @Multipart()
  Future<Response> recognizeMenu(
    @Part() String file,
  );
}
