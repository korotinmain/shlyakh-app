import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled route', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(routeProvider, (_, _) {});

    final route = await container.read(routeProvider.future);

    expect(route.constellations, hasLength(16));
    expect(route.constellations.first.id, 'Sge');
  });
}
