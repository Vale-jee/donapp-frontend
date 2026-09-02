import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/services/client_id_generator.dart';

void main() {
  const uuidV4Pattern =
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';
  final uuidV4 = RegExp(uuidV4Pattern, caseSensitive: false);

  test('genera clientId y operationId UUID v4 válidos y diferentes', () {
    const generator = UuidClientIdGenerator();
    final firstEntity = generator.newEntityId();
    final secondEntity = generator.newEntityId();
    final firstOperation = generator.newOperationId();
    final secondOperation = generator.newOperationId();

    expect(firstEntity, matches(uuidV4));
    expect(secondEntity, matches(uuidV4));
    expect(firstOperation, matches(uuidV4));
    expect(secondOperation, matches(uuidV4));
    expect({
      firstEntity,
      secondEntity,
      firstOperation,
      secondOperation,
    }, hasLength(4));
  });

  test('la abstracción puede sustituirse por valores deterministas', () {
    final generator = _DeterministicIdGenerator();
    expect(generator.newEntityId(), 'entity-fixed');
    expect(generator.newOperationId(), 'operation-fixed');
  });
}

final class _DeterministicIdGenerator implements ClientIdGenerator {
  @override
  String newEntityId() => 'entity-fixed';

  @override
  String newOperationId() => 'operation-fixed';
}
