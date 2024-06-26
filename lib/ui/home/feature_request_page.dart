import 'package:flutter/material.dart';
import 'package:possystem/components/linkify.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/translator.dart';

class FeatureRequestPage extends StatelessWidget {
  const FeatureRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PopButton()),
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              decoration: const BoxDecoration(
                // moon white
                color: Color(0xFFF4F6F0),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/feature_request_please.gif',
                key: const Key('feature_request_please'),
              ),
            ),
            const SizedBox(height: 14.0),
            Linkify.fromString(
              S.settingElfContent,
              textAlign: TextAlign.center,
            )
          ]),
        ),
      ),
    );
  }
}
