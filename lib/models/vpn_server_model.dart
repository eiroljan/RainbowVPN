import 'package:vpn_app/l10n/app_localizations.dart';

/// Data model for a VPN server entry.
///
/// [configAssetPath] is the path to the bundled `.ovpn` file in the assets
/// folder. [username] and [password] are optional — leave empty strings if
/// the server uses certificate-only auth.
class VpnServerModel {
  final String country;
  final String countryKey;
  final String flag;
  final String ping;
  final String configAssetPath;
  final String username;
  final String password;

  const VpnServerModel({
    required this.country,
    required this.countryKey,
    required this.flag,
    required this.ping,
    required this.configAssetPath,
    this.username = '',
    this.password = '',
  });

  String localizedCountry(AppLocalizations l) {
    switch (countryKey) {
      case 'countryUnitedStates': return l.countryUnitedStates;
      case 'countryUnitedKingdom': return l.countryUnitedKingdom;
      case 'countryGermany': return l.countryGermany;
      case 'countryJapan': return l.countryJapan;
      case 'countrySingapore': return l.countrySingapore;
      case 'countryAustralia': return l.countryAustralia;
      case 'countryCanada': return l.countryCanada;
      case 'countryNetherlands': return l.countryNetherlands;
      case 'countryMalaysia':
      case 'adminServer': return l.countryMalaysia;
      default: return country;
    }
  }
}
