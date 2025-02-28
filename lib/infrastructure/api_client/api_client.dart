import 'package:chopper/chopper.dart';

import '../../domain/eintities/request/favorite_body.dart';

part 'api_client.chopper.dart';

@ChopperApi(baseUrl: '/')
abstract class ApiClient extends ChopperService {
  static ApiClient create([ChopperClient? client]) => _$ApiClient(client);

  @Get(path: 'check_api_use_count')
  Future<Response> checkApiUseCount();

  @Get(path: 'prompt_with_text')
  Future<Response> promptWithText(
    @Body() Map<String, String> text,
  );

  @Get(path: 'open_ai/prompt_with_text')
  Future<Response> promptWithTextByOpenAI(
    @Body() Map<String, String> text,
  );

  @Post(path: 'prompt_with_image')
  @Multipart()
  Future<Response> promptWithImage(
    @Part() String image,
    @Part() String hint,
  );

  @Post(path: 'open_ai/prompt_with_image')
  @Multipart()
  Future<Response> promptWithImageByOpenAI(
    @Part() String image,
    @Part() String hint,
  );

  @Post(path: 'open_ai/prompt_with_menu')
  @Multipart()
  Future<Response> promptWithMenuByOpenAI(
    @Part() String image,
    @Part() List<String> favorites,
  );

  @Get(path: 'prompt_with_favorite')
  @Multipart()
  Future<Response> promptWithFavorite(
    @Body() FavoriteBody body,
  );

  @Get(path: 'get_latest_version')
  Future<Response> getLatestVersion();

  @Post(path: 'api/sake-preference/analyze')
  Future<Response> analyzeSakePreference(
    @Body() Map<String, dynamic> body,
  );
}
