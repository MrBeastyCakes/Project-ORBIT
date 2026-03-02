import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/planet.dart';
import '../providers/navigation_provider.dart';
import '../providers/search_provider.dart';
import '../../core/constants/theme_constants.dart';

class TelescopeScreen extends ConsumerStatefulWidget {
  const TelescopeScreen({super.key});

  @override
  ConsumerState<TelescopeScreen> createState() => _TelescopeScreenState();
}

class _TelescopeScreenState extends ConsumerState<TelescopeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    // Debounce is handled inside SearchNotifier.setQuery()
    ref.read(searchProvider.notifier).setQuery(_textController.text);
  }

  void _dismiss() {
    ref.read(searchProvider.notifier).deactivateTelescope();
    ref.read(searchProvider.notifier).clearSearch();
    Navigator.of(context).pop();
  }

  void _onResultTapped(Planet planet) {
    ref.read(searchProvider.notifier).deactivateTelescope();
    ref.read(searchProvider.notifier).clearSearch();
    ref.read(navigationProvider.notifier).zoomToBody(planet.id);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _textController.removeListener(_onQueryChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final resultItems = ref.watch(searchResultItemsProvider);

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: const Color(0xE6000000), // semi-transparent dark overlay
        child: GestureDetector(
          onTap: () {}, // prevent dismiss on inner content tap
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    style: const TextStyle(color: ThemeConstants.starColor),
                    cursorColor: ThemeConstants.accentColor,
                    decoration: InputDecoration(
                      hintText: 'Search notes, planets, stars...',
                      hintStyle: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: ThemeConstants.accentColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.close,
                          color:
                              ThemeConstants.starColor.withValues(alpha: 0.7),
                        ),
                        onPressed: _dismiss,
                      ),
                      filled: true,
                      fillColor: ThemeConstants.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Results / empty / loading area
                Expanded(
                  child: _buildBody(searchState, resultItems),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SearchState searchState, List<SearchResultItem> resultItems) {
    if (searchState.isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConstants.accentColor),
      );
    }

    if (searchState.query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.travel_explore,
        message: 'Search notes, planet names, or star names',
      );
    }

    if (resultItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'No matching planets found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: resultItems.length,
      itemBuilder: (context, index) {
        final item = resultItems[index];
        return _ResultCard(
          planet: item.planet,
          snippet: item.snippet,
          onTap: () => _onResultTapped(item.planet),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: ThemeConstants.starColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: ThemeConstants.starColor.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Planet planet;
  final String? snippet;
  final VoidCallback onTap;

  const _ResultCard({
    required this.planet,
    required this.snippet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ThemeConstants.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: ThemeConstants.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Planet color dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(planet.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planet.name,
                      style: const TextStyle(
                        color: ThemeConstants.starColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (snippet != null && snippet!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        snippet!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ThemeConstants.starColor.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ThemeConstants.accentColor.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
