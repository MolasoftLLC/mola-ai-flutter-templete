import 'package:chopper/chopper.dart';

part 'perplexity_api_client.chopper.dart';

@ChopperApi(baseUrl: '/api/perplexity')
abstract class PerplexityApiClient extends ChopperService {
  static PerplexityApiClient create([ChopperClient? client]) =>
      _$PerplexityApiClient(client);

  @Post(path: 'sake-info-batch')
  Future<Response> getSakeInfoBatch(
    @Body() Map<String, dynamic> body,
  );
}
