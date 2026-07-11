import 'package:flutter/material.dart';

enum OrderLinkType {
  uberEats,
  pickMe,
  unknown,
}

OrderLinkType parseOrderLink(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('ubereats.com') || lower.contains('uber.com')) {
    return OrderLinkType.uberEats;
  }
  if (lower.contains('pickme.lk') || lower.contains('pickme')) {
    return OrderLinkType.pickMe;
  }
  return OrderLinkType.unknown;
}

Color orderLinkBrandColor(OrderLinkType type) {
  switch (type) {
    case OrderLinkType.uberEats:
      return Colors.black;
    case OrderLinkType.pickMe:
      return const Color(0xFF009E60);
    case OrderLinkType.unknown:
      return const Color(0xFF6B6560);
  }
}

IconData orderLinkIcon(OrderLinkType type) {
  switch (type) {
    case OrderLinkType.uberEats:
      return Icons.directions_car_rounded;
    case OrderLinkType.pickMe:
      return Icons.local_taxi_rounded;
    case OrderLinkType.unknown:
      return Icons.shopping_bag_rounded;
  }
}

String orderLinkLabel(OrderLinkType type, String Function(String) localize) {
  switch (type) {
    case OrderLinkType.uberEats:
      return localize('offerOrderUberEats');
    case OrderLinkType.pickMe:
      return localize('offerOrderPickMe');
    case OrderLinkType.unknown:
      return localize('offerOrderVia');
  }
}
