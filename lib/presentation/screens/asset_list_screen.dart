import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/network_banner.dart';
import 'add_asset_screen.dart';
import '../../domain/entities/asset_entity.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg            = Color(0xFF0F1117);
  static const _surface       = Color(0xFF1A1D27);
  static const _accent        = Color(0xFF4F8EF7);
  static const _border        = Color(0xFF2E3347);
  static const _textPrimary   = Color(0xFFECEFF4);
  static const _textSecondary = Color(0xFF7B849A);
  static const _errorColor    = Color(0xFFFF5C72);

  // ── Conflict state ────────────────────────────────────────────────────────
  // Tracks the previous snapshot so we can diff against every new emission.
  List<AssetEntity>? _previousAssets;

  // The locally-resolved list that is actually rendered.
  List<AssetEntity> _resolvedAssets = [];

  void _mergeAndDetectConflicts(List<AssetEntity> incoming) {
    if (_previousAssets == null) {
      // First emission — no previous data to diff against.
      setState(() => _resolvedAssets = List.of(incoming));
      _previousAssets = List.of(incoming);
      return;
    }

    final previousById = {for (final a in _previousAssets!) a.id: a};
    final incomingById  = {for (final a in incoming) a.id: a};

    final List<AssetEntity> merged   = List.of(_resolvedAssets);
    final List<AssetEntity> conflicts = [];

    for (final newAsset in incoming) {
      final old = previousById[newAsset.id];

      if (old != null && old.timestamp != newAsset.timestamp) {
        // ── CONFLICT: same ID, different timestamp ──────────────────────────
        final idx = merged.indexWhere((a) => a.id == newAsset.id);
        if (idx != -1) {
          merged[idx] = newAsset;   // Replace old with incoming
        } else {
          merged.add(newAsset);
        }
        conflicts.add(newAsset);
      } else if (old == null) {
        // ── NEW asset ───────────────────────────────────────────────────────
        if (!merged.any((a) => a.id == newAsset.id)) {
          merged.add(newAsset);
        }
      }
      // else: identical — no action needed
    }

    // Remove assets that disappeared from the incoming list
    merged.removeWhere((a) => !incomingById.containsKey(a.id));

    setState(() => _resolvedAssets = merged);
    _previousAssets = List.of(incoming);

    // Fire a snackbar for every conflict found (debounced: clear first)
    if (conflicts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        for (final conflicted in conflicts) {
          _showConflictSnackbar(conflicted);
        }
      });
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _showConflictSnackbar(AssetEntity resolved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: _ConflictSnackbarContent(assetName: resolved.assetName),
      ),
    );
  }

  // ── Category helpers ──────────────────────────────────────────────────────
  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Equipment':      return const Color(0xFF4F8EF7);
      case 'Sample':         return const Color(0xFFA78BFA);
      case 'Infrastructure': return const Color(0xFF34D399);
      default:               return _textSecondary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Equipment':      return Icons.construction_rounded;
      case 'Sample':         return Icons.science_outlined;
      case 'Infrastructure': return Icons.account_balance_outlined;
      default:               return Icons.layers_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    // Listen to the provider; run diff on every emission.
    ref.listen<AsyncValue<List<AssetEntity>>>(
      assetListProvider,
      (_, next) {
        next.whenData(_mergeAndDetectConflicts);
      },
    );

    // Also watch so the widget rebuilds on loading / error states.
    final assetsAsync = ref.watch(assetListProvider);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          error: _errorColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map_outlined, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Field Asset Tracker',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          actions: [
            _SyncStatusChip(syncState: syncState),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
        ),
        body: Column(
          children: [
            const NetworkBanner(),
            Expanded(
              child: assetsAsync.when(
                data: (_) {
                  // Render from _resolvedAssets (post-conflict-merge), not raw provider data.
                  if (_resolvedAssets.isEmpty) return const _EmptyState();
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _resolvedAssets.length,
                    itemBuilder: (context, index) {
                      final asset = _resolvedAssets[index];
                      final isPending =
                          asset.syncStatus == SyncStatus.pendingSync;
                      final isItemInTransit =
                          syncState == SyncState.syncing && isPending;
                      return _AssetCard(
                        asset: asset,
                        isPending: isPending,
                        isItemInTransit: isItemInTransit,
                        getCategoryColor: _getCategoryColor,
                        getCategoryIcon: _getCategoryIcon,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: _accent, strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: _errorColor, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Error loading assets',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$err',
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddAssetScreen()),
          ),
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'New Asset',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }
}

// ── Conflict Snackbar Content ─────────────────────────────────────────────────
class _ConflictSnackbarContent extends StatelessWidget {
  final String assetName;
  const _ConflictSnackbarContent({required this.assetName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFBBF24).withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.35)),
            ),
            child: const Icon(Icons.sync_problem_rounded,
                color: Color(0xFFFBBF24), size: 18),
          ),
          const SizedBox(width: 12),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Conflict Resolved',
                  style: TextStyle(
                    color: Color(0xFFECEFF4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: Color(0xFF7B849A), fontSize: 12),
                    children: [
                      const TextSpan(text: 'Newer version of '),
                      TextSpan(
                        text: '"$assetName"',
                        style: const TextStyle(
                          color: Color(0xFFECEFF4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' replaced the local copy'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4F8EF7).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF4F8EF7).withOpacity(0.35)),
            ),
            child: const Text(
              'REPLACED',
              style: TextStyle(
                color: Color(0xFF4F8EF7),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Asset Card ────────────────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final AssetEntity asset;
  final bool isPending;
  final bool isItemInTransit;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;

  const _AssetCard({
    required this.asset,
    required this.isPending,
    required this.isItemInTransit,
    required this.getCategoryColor,
    required this.getCategoryIcon,
  });

  static const _surface       = Color(0xFF1A1D27);
  static const _border        = Color(0xFF2E3347);
  static const _textPrimary   = Color(0xFFECEFF4);
  static const _textSecondary = Color(0xFF7B849A);

  Color get _statusColor {
    switch (asset.status) {
      case 'Good':         return const Color(0xFF34D399);
      case 'Needs Repair': return const Color(0xFFFBBF24);
      case 'Broken':       return const Color(0xFFFF5C72);
      default:             return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = getCategoryColor(asset.category);
    final catIcon  = getCategoryIcon(asset.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: catColor.withOpacity(0.3)),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.assetName,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _Pill(label: asset.category, color: catColor),
                      const SizedBox(width: 6),
                      _Pill(label: asset.status, color: _statusColor),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: _textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${asset.latitude.toStringAsFixed(5)},  '
                        '${asset.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            _SyncTrailing(
              isItemInTransit: isItemInTransit,
              isPending: isPending,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Sync trailing ─────────────────────────────────────────────────────────────
class _SyncTrailing extends StatelessWidget {
  final bool isItemInTransit;
  final bool isPending;
  const _SyncTrailing({required this.isItemInTransit, required this.isPending});

  @override
  Widget build(BuildContext context) {
    if (isItemInTransit) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFFBBF24),
        ),
      );
    }
    if (isPending) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cloud_upload_outlined,
              color: Color(0xFFFBBF24), size: 20),
          SizedBox(height: 2),
          Text(
            'PENDING',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.cloud_done_outlined, color: Color(0xFF34D399), size: 20),
        SizedBox(height: 2),
        Text(
          'SYNCED',
          style: TextStyle(
            color: Color(0xFF34D399),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Sync status chip ──────────────────────────────────────────────────────────
class _SyncStatusChip extends StatelessWidget {
  final SyncState syncState;
  const _SyncStatusChip({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final isSyncing = syncState == SyncState.syncing;
    final color = isSyncing
        ? const Color(0xFFFBBF24)
        : const Color(0xFF34D399);
    final label = isSyncing ? 'Syncing…' : 'Online';
    final icon  = isSyncing ? Icons.sync_rounded : Icons.wifi_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const _accent        = Color(0xFF4F8EF7);
  static const _textPrimary   = Color(0xFFECEFF4);
  static const _textSecondary = Color(0xFF7B849A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: _accent, size: 36),
          ),
          const SizedBox(height: 18),
          const Text(
            'No assets recorded yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "New Asset" to log your first field entry',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}