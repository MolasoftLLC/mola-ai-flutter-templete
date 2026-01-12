import 'package:chopper/chopper.dart';

part 'sake_menu_recognition_api_client.chopper.dart';

@ChopperApi(baseUrl: '/api')
abstract class SakeMenuRecognitionApiClient extends ChopperService {
  static SakeMenuRecognitionApiClient create([ChopperClient? client]) =>
      _$SakeMenuRecognitionApiClient(client);

  @Post(path: 'menu-recognition/recognize')
  @Multipart()
  Future<Response> recognizeMenu(
    @Part() String file,
  );

  @Post(path: 'menu-recognition/extract')
  @Multipart()
  Future<Response> extractSakeInfo(
    @Part() String file,
  );

  @Post(path: 'menu-recognition/extract')
  Future<Response> extractSakeInfoJson(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'menu-recognition/perplexity/sake-info-batch')
  Future<Response> getSakeInfoBatch(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'menu-recognition/perplexity/sake-info')
  Future<Response> getSakeInfo(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-bottle/recognize')
  @Multipart()
  Future<Response<Map<String, dynamic>>> recognizeSakeBottle(
    @Part() String file,
  );

  @Post(path: 'sake-bottle/comprehensive-analysis')
  Future<Response<Map<String, dynamic>>> comprehensiveSakeBottleAnalysis(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-preference/analyze')
  Future<Response> analyzeSakePreference(
    @Body() Map<String, dynamic> body,
  );
}
