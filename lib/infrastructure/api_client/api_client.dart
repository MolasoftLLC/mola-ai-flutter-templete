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

  @Post(path: 'saved-sakes/analysis-start')
  Future<Response> uploadSavedSakeAnalysisStart(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'saved-sakes/analysis-complete')
  Future<Response> uploadSavedSakeAnalysisComplete(
    @Body() Map<String, dynamic> body,
  );

  @Get(path: 'saved-sakes')
  Future<Response> fetchSavedSakes(
    @Query('userId') String userId,
  );

  @Post(path: 'saved-sakes/{savedId}/remove')
  Future<Response> removeSavedSake(
    @Path('savedId') String savedId,
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'saved-sakes/{savedId}/images')
  Future<Response> uploadSavedSakeImage(
    @Path('savedId') String savedId,
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'saved-sakes/{savedId}/images/delete')
  Future<Response> deleteSavedSakeImage(
    @Path('savedId') String savedId,
    @Body() Map<String, dynamic> body,
  );

  @Get(path: 'favorites')
  Future<Response> fetchFavorites(
    @Query('userId') String userId,
  );

  @Post(path: 'favorites')
  Future<Response> addFavorite(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'favorites/delete')
  Future<Response> removeFavorite(
    @Body() Map<String, dynamic> body,
  );

  @Get(path: 'preferences')
  Future<Response> fetchPreferences(
    @Query('userId') String userId,
  );

  @Post(path: 'preferences')
  Future<Response> updatePreferences(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-users/register')
  Future<Response> registerSakeUser(
    @Body() Map<String, dynamic> body,
  );

  @Get(path: 'sake-users/me')
  Future<Response> fetchSakeUser(
    @Query('userId') String userId,
  );

  @Post(path: 'sake-users/username')
  Future<Response> updateUsername(
    @Body() Map<String, dynamic> body,
  );

  @Post(path: 'sake-users/delete')
  Future<Response> deleteSakeUser(
    @Body() Map<String, dynamic> body,
  );
}
