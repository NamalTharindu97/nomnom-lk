import '../models/offer.dart';

class MockOfferService {
  Future<List<Offer>> fetchOffers() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return const [
      Offer(
        id: 'offer-kottu-01',
        restaurantName: 'Pettah Kottu Cart',
        foodName: 'Cheese Chicken Kottu',
        description:
            'Chopped godamba roti tossed with chicken, melted cheese, leeks, egg, and a spicy house gravy.',
        originalPrice: 1650,
        offerPrice: 1190,
        discountLabel: '28% off',
        imageUrl:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=1200&q=80',
        location: 'Colombo 11',
      ),
      Offer(
        id: 'offer-rice-curry-02',
        restaurantName: 'Galle Rice House',
        foodName: 'Chicken Rice & Curry',
        description:
            'Steamed samba rice with chicken curry, dhal, tempered greens, papadam, and coconut sambol.',
        originalPrice: 1250,
        offerPrice: 890,
        discountLabel: 'Rs. 360 off',
        imageUrl:
            'https://images.unsplash.com/photo-1604908176997-4313c0ce7061?auto=format&fit=crop&w=1200&q=80',
        location: 'Galle Fort',
      ),
      Offer(
        id: 'offer-hoppers-03',
        restaurantName: 'Hopper Street',
        foodName: 'Egg Hopper Combo',
        description:
            'Crispy bowl-shaped hoppers with runny egg centers, katta sambol, and seeni sambol.',
        originalPrice: 950,
        offerPrice: 690,
        discountLabel: '27% off',
        imageUrl:
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=1200&q=80',
        location: 'Nugegoda',
      ),
      Offer(
        id: 'offer-kebab-04',
        restaurantName: 'Marine Drive Grill',
        foodName: 'Spicy Chicken Kebab Wrap',
        description:
            'Chargrilled chicken kebab wrapped with garlic sauce, pickled onion, fresh salad, and fries.',
        originalPrice: 1750,
        offerPrice: 1290,
        discountLabel: 'Combo deal',
        imageUrl:
            'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=1200&q=80',
        location: 'Bambalapitiya',
      ),
      Offer(
        id: 'offer-fried-rice-05',
        restaurantName: 'Wok Lanka',
        foodName: 'Seafood Fried Rice',
        description:
            'Wok-fired rice with prawns, cuttlefish, egg, spring onion, chili paste, and garlic soy.',
        originalPrice: 1480,
        offerPrice: 1090,
        discountLabel: 'Rs. 390 off',
        imageUrl:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=1200&q=80',
        location: 'Rajagiriya',
      ),
      Offer(
        id: 'offer-short-eats-06',
        restaurantName: 'Bamba Bakery',
        foodName: 'Short Eats Party Box',
        description:
            'A warm box of fish buns, chicken rolls, patties, and cutlets for tea-time sharing.',
        originalPrice: 2200,
        offerPrice: 1690,
        discountLabel: '23% off',
        imageUrl:
            'https://images.unsplash.com/photo-1625938144755-652e08e359b7?auto=format&fit=crop&w=1200&q=80',
        location: 'Wellawatte',
      ),
      Offer(
        id: 'offer-string-hoppers-07',
        restaurantName: 'Kandy Morning Cafe',
        foodName: 'String Hopper Breakfast',
        description:
            'Soft string hoppers served with kiri hodi, coconut sambol, potato curry, and pol sambol.',
        originalPrice: 980,
        offerPrice: 720,
        discountLabel: 'Breakfast save',
        imageUrl:
            'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=1200&q=80',
        location: 'Kandy',
      ),
      Offer(
        id: 'offer-lamprais-08',
        restaurantName: 'Dutch Burgher Table',
        foodName: 'Chicken Lamprais',
        description:
            'Banana leaf baked rice with chicken curry, brinjal moju, frikkadel, ash plantain, and sambol.',
        originalPrice: 2100,
        offerPrice: 1590,
        discountLabel: 'Lunch special',
        imageUrl:
            'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=1200&q=80',
        location: 'Mount Lavinia',
      ),
      Offer(
        id: 'offer-pittu-09',
        restaurantName: 'Jaffna Spice Room',
        foodName: 'Pittu with Crab Curry',
        description:
            'Steamed pittu layered with coconut, served with rich northern-style crab curry and gravy.',
        originalPrice: 2400,
        offerPrice: 1890,
        discountLabel: 'Rs. 510 off',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
        location: 'Jaffna',
      ),
      Offer(
        id: 'offer-roti-10',
        restaurantName: 'Ella Roti Stop',
        foodName: 'Pol Roti & Lunu Miris',
        description:
            'Coconut roti grilled to order with lunu miris, dhal curry, and a cup of ginger tea.',
        originalPrice: 850,
        offerPrice: 590,
        discountLabel: '30% off',
        imageUrl:
            'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
        location: 'Ella',
      ),
    ];
  }
}
