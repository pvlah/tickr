import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coingecko/coingecko_client.dart';
import 'repositories/market_repository.dart';

/// Dependency-injection providers for the data layer.
///
/// Providers are Riverpod's DI graph. A plain [Provider] exposes a value and
/// caches it for the app's lifetime. Because the repository is *provided* (not
/// `new`-ed inside widgets), tests can override [coinGeckoClientProvider] with
/// a fake and the whole graph below it uses the fake — no mocking frameworks.

/// The raw HTTP client. One instance for the app.
final coinGeckoClientProvider =
    Provider<CoinGeckoClient>((ref) => CoinGeckoClient());

/// The repository, built from the client. `ref.watch` here means: if the
/// client provider were ever replaced, the repository rebuilds with it.
final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepository(ref.watch(coinGeckoClientProvider)),
);
