import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'pages/buy_chronos/buy_chronos_controller.dart';
import 'pages/sell_chronos/sell_chronos_controller.dart';

void main() {
        runApp(const ChronoraFlutter());
}

class ChronoraFlutter extends StatelessWidget {
        const ChronoraFlutter({super.key});

        @override
        Widget build(BuildContext context) {
                return MultiProvider(
                    providers: [
                        ChangeNotifierProvider(create: (_) => BuyChronosController()),
                        ChangeNotifierProvider(create: (_) => SellChronosController()),
                    ],
                    child: MaterialApp(
                        title: 'Chronora',
                        theme: ThemeData(
                            primarySwatch: Colors.amber,
                            fontFamily: 'Roboto',
                            scaffoldBackgroundColor: const Color(0xFF0B0C0C),
                        ),
                        initialRoute: AppRoutes.login,
                        routes: AppRoutes.routes,
                        debugShowCheckedModeBanner: false,
                    ),
                );
        }
}