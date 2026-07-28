import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/widgets/shimmer_loading.dart';

void main() {
  testWidgets('offer and restaurant shimmers fit a 320px phone',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              OfferCardShimmer(),
              RestaurantCardShimmer(),
              HotOfferShimmer(width: 176, height: 264),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.getSize(find.byType(OfferCardShimmer)).width, 320);
    expect(tester.getSize(find.byType(RestaurantCardShimmer)).width, 320);
    expect(tester.getSize(find.byType(HotOfferShimmer)), const Size(176, 264));
    expect(tester.takeException(), isNull);
  });
}
