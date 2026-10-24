import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/places_service.dart';

const _geojson = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[2.5,48.5]},
  "properties":{"id":"00000","city":"Villeexemple","postcode":"99000","name":"Villeexemple"}}
]}''';

void main() {
  test('searchCities appelle la Geoplateforme et parse le GeoJSON', () async {
    Uri? called;
    final service = PlacesService.withClient(MockClient((request) async {
      called = request.url;
      return http.Response(_geojson, 200);
    }));

    final result = await service.searchCities('ville');

    expect(called!.host, 'data.geopf.fr');
    expect(called!.path, '/geocodage/search');
    expect(called!.queryParameters['q'], 'ville');
    expect(called!.queryParameters['type'], 'municipality');
    expect(called!.queryParameters['limit'], '5');
    expect(result, hasLength(1));
    expect(result.first.city, 'Villeexemple');
    expect(result.first.postalCode, '99000');
    expect(result.first.displayName, 'Villeexemple 99000');
    expect(result.first.longitude, 2.5);
    expect(result.first.latitude, 48.5);
  });

  test('searchAddresses utilise aussi la Geoplateforme', () async {
    Uri? called;
    final service = PlacesService.withClient(MockClient((request) async {
      called = request.url;
      return http.Response(_geojson, 200);
    }));

    final result = await service.searchAddresses('1 rue exemple');

    expect(called!.host, 'data.geopf.fr');
    expect(called!.path, '/geocodage/search');
    expect(result, hasLength(1));
  });

  test('searchCities rend une liste vide sur erreur réseau', () async {
    final service = PlacesService.withClient(
      MockClient((_) async => throw http.ClientException('hors ligne')),
    );
    expect(await service.searchCities('ville'), isEmpty);
  });
}
