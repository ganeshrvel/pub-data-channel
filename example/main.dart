/// Data channel could be used to transport data across the dart program
/// Data channel can move any data ranging from external http api response to internal data.
///
/// For usage examples refer:
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/data_sources/login_local_data_source.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/controllers/login_controller.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/data/repositories/login_repository.dart
/// https://github.com/ganeshrvel/flutter_mobx_dio_boilerplate/blob/master/lib/features/login/ui/store/login_store.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:data_channel/data_channel.dart';
import 'models.dart';

class StarwarsDataController {
  final _starwarsDataSource = StarwarsDataSource();

  StarwarsDataController();

  Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
    final _starwarsData = await _starwarsDataSource.getStarwarsCharacters();

    if (_starwarsData.hasError) {
      return DC.error(
        _starwarsData.error!,
      );
    }

    return DC.data(
      _starwarsData.data,
    );
  }
}

class StarwarsDataSource {
  StarwarsDataSource();

  Future<DC<Exception, StarwarsResponse>> getStarwarsCharacters() async {
    try {
      StarwarsResponse? _starWarsData;
      Exception? _exception;

      final _client = HttpClient();
      final uri = Uri.parse('https://starwars-api.com/characters');

      final request = await _client.getUrl(uri);
      final _response = await request.close();
      final responseBody = await _response.transform(utf8.decoder).join();

      if (_response.statusCode == 200) {
        _starWarsData = StarwarsResponse.fromJson(
            json.decode(responseBody) as Map<String, dynamic>);
      } else {
        _exception = Exception('No data available');
      }

      if (_exception != null) {
        return DC.error(
          _exception,
        );
      }

      return DC.data(
        _starWarsData,
      );
    } on Exception {
      return DC.error(
        Exception('Some error occured'),
      );
    }
  }
}

Future<void> main() async {
  final _starwarsDataController = StarwarsDataController();
  final _starwarsData = await _starwarsDataController.getStarwarsCharacters();

  _starwarsData.pick(
    onError: (error) {
      // ignore: avoid_print
      print(error);
    },
    onData: (data) {
      // ignore: avoid_print
      print(data);
    },
    onNoData: () {},
  );
}
