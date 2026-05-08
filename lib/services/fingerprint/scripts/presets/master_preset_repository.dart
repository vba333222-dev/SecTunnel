import 'package:sec_tunnel/models/identity/master_identity.dart';
import 'package:sec_tunnel/services/fingerprint/identity_system/identity_factory.dart';

class MasterPresetRepository {
  static final List<MasterIdentity> profiles = [
    IdentityFactory.generate(
      family: 'Google Pixel',
      model: 'Pixel 8 Pro',
      region: 'US',
      seed: 'stable-pixel-cluster',
    ),
    IdentityFactory.generate(
      family: 'Samsung Galaxy',
      model: 'SM-S928B',
      region: 'ID',
      seed: 'stable-galaxy-cluster',
    ),
    IdentityFactory.generate(
      family: 'Windows Desktop',
      model: 'PC',
      region: 'US',
      seed: 'stable-win-cluster',
    ),
  ];

  static MasterIdentity get defaultProfile => profiles.first;
  static List<MasterIdentity> getPresets() => profiles;
}
