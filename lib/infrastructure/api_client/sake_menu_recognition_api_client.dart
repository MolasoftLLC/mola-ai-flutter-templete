import 'package:chopper/chopper.dart';
import 'package:http/http.dart' show MultipartFile;

part 'sake_menu_recognition_api_client.chopper.dart';

@ChopperApi(baseUrl: '/api')
abstract class SakeMenuRecognitionApiClient extends ChopperService {
  static SakeMenuRecognitionApiClient create([ChopperClient? client]) =>
      _$SakeMenuRecognitionApiClient(client);

  @Post(path: 'menu-recognition/recognize')
  @Multipart()
  Future<Response> recognizeMenu(@Part() String file);

  @Post(path: 'menu-recognition/extract')
  @Multipart()
  Future<Response> extractSakeInfo(@Part() String file);

  @Post(path: 'menu-recognition/extract')
  Future<Response> extractSakeInfoJson(@Body() Map<String, dynamic> body);

  @Post(path: 'menu-recognition/perplexity/sake-info-batch')
  Future<Response> getSakeInfoBatch(@Body() Map<String, dynamic> body);

  @Post(path: 'menu-recognition/perplexity/sake-info')
  Future<Response> getSakeInfo(@Body() Map<String, dynamic> body);

  @Post(path: 'sakes/resolve-candidate')
  Future<Response<Map<String, dynamic>>> resolveSakeCandidate(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-bottle/recognize')
  @Multipart()
  Future<Response<Map<String, dynamic>>> recognizeSakeBottle(
    @Part() String file,
    @Part() String? secondaryFile,
  );

  @Post(path: 'sake-bottle/scan/ai-candidates')
  @Multipart()
  Future<Response<Map<String, dynamic>>> recognizeSakeBottleCandidates(
    @Part() String file,
    @Part() String? secondaryFile,
  );

  @Post(path: 'sake-bottle/comprehensive-analysis')
  Future<Response<Map<String, dynamic>>> comprehensiveSakeBottleAnalysis(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-bottle/scan/front')
  @Multipart()
  Future<Response<Map<String, dynamic>>> scanSakeFrontLabel(
    @PartFile('image') MultipartFile image,
    @Part('locale') String locale,
  );

  @Post(path: 'sake-bottle/scan/{scanSessionId}/back')
  @Multipart()
  Future<Response<Map<String, dynamic>>> scanSakeBackLabel(
    @Path('scanSessionId') String scanSessionId,
    @PartFile('image') MultipartFile image,
    @Part('locale') String locale,
  );

  @Post(path: 'sake-bottle/scan/{scanSessionId}/confirm')
  Future<Response<Map<String, dynamic>>> confirmScannedSake(
    @Path('scanSessionId') String scanSessionId,
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-bottle/scan/{scanSessionId}/reject')
  Future<Response> rejectScannedSakeCandidates(
    @Path('scanSessionId') String scanSessionId,
    @Body() Map<String, dynamic> body,
  );

  @Get(path: 'sakes/{sakeId}/overview')
  Future<Response<Map<String, dynamic>>> fetchSakeOverview(
    @Path('sakeId') int sakeId,
    @Query('locale') String locale,
    @Query('trackView') bool trackView,
  );

  @Post(path: 'sake-preference/analyze')
  Future<Response> analyzeSakePreference(@Body() Map<String, dynamic> body);
}
