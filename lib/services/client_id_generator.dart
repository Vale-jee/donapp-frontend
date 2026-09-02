import 'package:uuid/uuid.dart';

abstract interface class ClientIdGenerator {
  String newEntityId();

  String newOperationId();
}

final class UuidClientIdGenerator implements ClientIdGenerator {
  const UuidClientIdGenerator([this._uuid = const Uuid()]);

  final Uuid _uuid;

  @override
  String newEntityId() => _uuid.v4();

  @override
  String newOperationId() => _uuid.v4();
}
