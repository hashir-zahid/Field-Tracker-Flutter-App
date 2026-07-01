import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/providers.dart';

class NetworkBanner extends ConsumerStatefulWidget {
  const NetworkBanner({super.key});

  @override
  ConsumerState<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends ConsumerState<NetworkBanner> {
  bool _showSuccessBanner = false;

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    // Watch for transitions between offline and online states safely without rebuilding loops
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        final wasOffline = previous?.value?.contains(ConnectivityResult.none) ?? false;
        final isNowOnline = !(next.value?.contains(ConnectivityResult.none) ?? true);

        if (wasOffline && isNowOnline) {
          setState(() => _showSuccessBanner = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _showSuccessBanner = false);
            }
          });
        }
      },
    );

    return connectivityAsync.when(
      data: (results) {
        final isOffline = results.contains(ConnectivityResult.none);
        final isVisible = isOffline || _showSuccessBanner;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          height: isVisible ? 40.0 : 0.0,
          color: isOffline ? Colors.amber.shade800 : Colors.green.shade700,
          width: double.infinity,
          child: isVisible
              ? Center(
                  child: Text(
                    isOffline 
                        ? '⚠️ Working Offline — Saving changes locally' 
                        : '✅ Connection Restored — Syncing data',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 13,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}