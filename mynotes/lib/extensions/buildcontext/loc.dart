import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter_gen/gen_l10n/app_localizations.dart'
    show AppLocalizations;

extension Localization on BuildContext {
  ///aqui criamos uma extensao do build context apenas pq o [AppLocalizations] é nullable, e nós nao queremos usar ele nullo, entao fizemos um getter para solucionar facilmente
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
