import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

/// Id of the signed-in user. `'local'` until registration exists.
@Riverpod(keepAlive: true)
String currentUserId(Ref ref) => 'local';
