import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/models/analysis/analysis.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:provider/provider.dart';

import 'debug/setup_menu.dart';
import 'firebase_compatible_options.dart';
import 'helpers/logger.dart';
import 'models/repository/cashier.dart';
import 'models/repository/menu.dart';
import 'models/repository/order_attributes.dart';
import 'models/repository/quantities.dart';
import 'models/repository/replenisher.dart';
import 'models/repository/seller.dart';
import 'models/repository/stock.dart';
import 'my_app.dart';
import 'services/cache.dart';
import 'services/database.dart';
import 'services/storage.dart';
import 'settings/collect_events_setting.dart';
import 'settings/settings_provider.dart';

void main() async {
  // Not all errors are caught by Flutter. Sometimes, errors are instead caught by Zones.
  await runZonedGuarded<Future<void>>(
    () async {
      // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      if (kDebugMode) {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
        await FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
      }

      await Database.instance.initialize(logWhenQuery: isLocalTest);
      await Storage.instance.initialize();
      await Cache.instance.initialize();

      final settings = SettingsProvider(SettingsProvider.allSettings);
      Log.allowSendEvents = SettingsProvider.of<CollectEventsSetting>().value;

      await Stock().initialize();
      await Quantities().initialize();
      await OrderAttributes().initialize();
      await Replenisher().initialize();
      await Cashier().reset();
      await Analysis().initialize();
      // Last for setup ingredient and quantity
      await Menu().initialize();

      if (kDebugMode) {
        await debugSetupMenu();
      }

      /// Why use provider?
      /// https://stackoverflow.com/questions/57157823/provider-vs-inheritedwidget
      runApp(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settings,
          ),
          ChangeNotifierProvider<Menu>(
            create: (_) => Menu.instance,
          ),
          ChangeNotifierProvider<Stock>(
            create: (_) => Stock.instance,
          ),
          ChangeNotifierProvider<Quantities>(
            create: (_) => Quantities.instance,
          ),
          ChangeNotifierProvider<Replenisher>(
            create: (_) => Replenisher.instance,
          ),
          ChangeNotifierProvider<OrderAttributes>(
            create: (_) => OrderAttributes.instance,
          ),
          ChangeNotifierProvider<Seller>(
            create: (_) => Seller.instance,
          ),
          ChangeNotifierProvider<Cashier>(
            create: (_) => Cashier.instance,
          ),
          ChangeNotifierProvider<Cart>(
            create: (_) => Cart.instance,
          ),
        ],
        child: MyApp(settings: settings),
      ));
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}
