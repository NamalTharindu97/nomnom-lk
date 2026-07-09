import 'package:share_plus/share_plus.dart';

import '../models/offer.dart';

class ShareService {
  Future<void> shareOffer(Offer offer) async {
    final text = _formatShareText(offer);
    await Share.share(text, subject: offer.title);
  }

  String _formatShareText(Offer offer) {
    final dealText = offer.discountPercent > 0
        ? '${offer.discountPercent.round()}% OFF'
        : 'LKR ${offer.offerPrice}';
    return 'Check out this deal at ${offer.restaurantName}!\n'
        '$dealText on ${offer.title}\n\n'
        '${offer.description}\n\n'
        'Download NomNom LK to discover Sri Lanka\'s best food deals!';
  }
}
