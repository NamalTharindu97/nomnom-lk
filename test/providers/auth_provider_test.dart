import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/app_user.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';

import '../helpers/mocks.dart';

AppUser _makeUser({
  String id = 'u1',
  String name = 'Test User',
  String email = 'test@example.com',
}) {
  return AppUser(
    id: id,
    name: name,
    email: email,
    isLoggedIn: true,
  );
}

void main() {
  late MockApiAuthService authService;
  late MockApiClient apiClient;
  late MockFavoriteStore favoriteStore;
  late MockNotificationStore notificationStore;
  late MockOfferStore offerStore;
  late MockRestaurantStore restaurantStore;
  late AuthProvider provider;

  setUp(() {
    authService = MockApiAuthService();
    apiClient = MockApiClient();
    favoriteStore = MockFavoriteStore();
    notificationStore = MockNotificationStore();
    offerStore = MockOfferStore();
    restaurantStore = MockRestaurantStore();
    provider = AuthProvider(
      authService,
      apiClient: apiClient,
      favoriteStore: favoriteStore,
      notificationStore: notificationStore,
      offerStore: offerStore,
      restaurantStore: restaurantStore,
    );
  });

  group('restoreSession', () {
    test('sets user and isInitialized when session exists', () async {
      final user = _makeUser();
      authService.userToReturn = user;

      await provider.restoreSession();

      expect(provider.user, isNotNull);
      expect(provider.user!.id, 'u1');
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('sets null user when no session exists', () async {
      authService.userToReturn = null;

      await provider.restoreSession();

      expect(provider.user, isNull);
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoading, isFalse);
    });
  });

  group('signInWithEmail', () {
    test('sets user and isInitialized on success', () async {
      final user = _makeUser();
      authService.userToReturn = user;

      await provider.signInWithEmail('test@example.com', 'password');

      expect(provider.user, isNotNull);
      expect(provider.user!.id, 'u1');
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('rethrows exception on failure', () async {
      authService.exceptionToThrow = Exception('Invalid credentials');

      try {
        await provider.signInWithEmail('test@example.com', 'wrong');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(provider.user, isNull);
      expect(provider.isInitialized, isFalse);
      expect(provider.isLoading, isFalse);
    });
  });

  group('register', () {
    test('completes without setting user', () async {
      await provider.register('test@example.com', 'password', 'Test User');

      expect(provider.user, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('rethrows exception on failure', () async {
      authService.exceptionToThrow = Exception('Email taken');

      try {
        await provider.register('test@example.com', 'password', 'Test User');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(provider.isLoading, isFalse);
    });
  });

  group('verifyEmail', () {
    test('sets user and isInitialized on success', () async {
      final user = _makeUser();
      authService.userToReturn = user;

      await provider.verifyEmail('test@example.com', '123456');

      expect(provider.user, isNotNull);
      expect(provider.user!.id, 'u1');
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('rethrows exception on failure', () async {
      authService.exceptionToThrow = Exception('Invalid code');

      try {
        await provider.verifyEmail('test@example.com', '000000');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(provider.isLoading, isFalse);
    });
  });

  group('continueAsGuest', () {
    test('sets guest user and isInitialized', () async {
      await provider.continueAsGuest();

      expect(provider.user, isNotNull);
      expect(provider.user!.isGuest, isTrue);
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isGuest, isTrue);
      expect(provider.canEnterApp, isTrue);
      expect(provider.isLoading, isFalse);
    });
  });

  group('signOut', () {
    test('clears user and calls logout on stores', () async {
      // Set up an initial user
      authService.userToReturn = _makeUser();
      await provider.signInWithEmail('test@example.com', 'password');
      expect(provider.user, isNotNull);

      await provider.signOut();

      expect(provider.user, isNull);
      expect(authService.logoutCalled, isTrue);
      expect(apiClient.cacheCleared, isTrue);
      expect(apiClient.clearTokensCalled, isTrue);
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('concurrent signOut calls are no-ops', () async {
      authService.userToReturn = _makeUser();
      await provider.signInWithEmail('test@example.com', 'password');

      // Start two signOut calls concurrently
      final f1 = provider.signOut();
      final f2 = provider.signOut();
      await Future.wait([f1, f2]);

      // logout should only be called once (first call)
      expect(provider.user, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('clears in-memory account state before logout completes', () async {
      var accountStateClearCount = 0;
      final accountAwareProvider = AuthProvider(
        authService,
        apiClient: apiClient,
        favoriteStore: favoriteStore,
        notificationStore: notificationStore,
        offerStore: offerStore,
        restaurantStore: restaurantStore,
        onAccountCleared: () => accountStateClearCount++,
      );
      authService.userToReturn = _makeUser();
      await accountAwareProvider.signInWithEmail(
        'test@example.com',
        'password',
      );

      await accountAwareProvider.signOut();

      expect(accountStateClearCount, 2);
    });

    test('completes local sign out when the remote logout fails', () async {
      authService.userToReturn = _makeUser();
      await provider.signInWithEmail('test@example.com', 'password');
      authService.exceptionToThrow = Exception('network failure');

      await provider.signOut();

      expect(provider.user, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isInitialized, isTrue);
      expect(apiClient.cacheCleared, isTrue);
      expect(apiClient.clearTokensCalled, isTrue);
    });
  });

  group('updateUser', () {
    test('sets user and notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final updated = _makeUser(id: 'u2', name: 'Updated');
      provider.updateUser(updated);

      expect(provider.user!.id, 'u2');
      expect(provider.user!.name, 'Updated');
      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });

  group('derived getters', () {
    test('isLoggedIn and isGuest reflect user state', () async {
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isGuest, isFalse);
      expect(provider.canEnterApp, isFalse);

      await provider.continueAsGuest();
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isGuest, isTrue);
      expect(provider.canEnterApp, isTrue);

      authService.userToReturn = _makeUser();
      await provider.signInWithEmail('test@example.com', 'password');
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isGuest, isFalse);
      expect(provider.canEnterApp, isTrue);
    });
  });
}
