import '../../landlord/models/organization.dart';
import 'app_user.dart';

class Session {
  const Session({required this.token, required this.user, this.organization});

  final String token;
  final AppUser user;
  final Organization? organization;

  @override
  String toString() => 'Session(user: ${user.id}, role: ${user.role.name})';
}
