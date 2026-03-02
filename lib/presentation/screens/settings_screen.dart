import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/color_picker_dialog.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/constants/theme_constants.dart';

// ---------------------------------------------------------------------------
// Hive preferences key constants
// ---------------------------------------------------------------------------
const String _kPrefsBox = 'preferences';
const String _kDefaultBlackHoleColor = 'defaultBlackHoleColor';
const String _kDefaultStarColor = 'defaultStarColor';
const String _kDefaultPlanetColor = 'defaultPlanetColor';

const int _defaultBlackHoleColorValue = 0xFF2D1B69;
const int _defaultStarColorValue = 0xFFFFF8E7;
const int _defaultPlanetColorValue = 0xFF4A90D9;

// ---------------------------------------------------------------------------
// Provider for the preferences box (opened lazily in main or on first access)
// ---------------------------------------------------------------------------
final _prefsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(_kPrefsBox);
});

// ---------------------------------------------------------------------------
// Helper to read a color pref with a fallback default
// ---------------------------------------------------------------------------
int _readColor(Box<dynamic> box, String key, int defaultValue) {
  final value = box.get(key);
  if (value is int) return value;
  return defaultValue;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConstants.surfaceColor,
        title: const Text(
          'Settings',
          style: TextStyle(color: ThemeConstants.starColor),
        ),
        iconTheme: const IconThemeData(color: ThemeConstants.starColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          _SectionHeader(title: 'Account'),
          Card(
            color: ThemeConstants.surfaceColor,
            child: Column(
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ThemeConstants.accentColor,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(color: ThemeConstants.starColor),
                    ),
                    subtitle: Text(
                      user.email,
                      style: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: ThemeConstants.accentColor,
                    ),
                    title: Text(
                      user.tier == UserTier.paid ? 'Paid' : 'Free',
                      style: const TextStyle(color: ThemeConstants.starColor),
                    ),
                    subtitle: Text(
                      user.tier == UserTier.paid
                          ? 'Full access'
                          : 'Limited to 2 categories',
                      style: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ] else ...[
                  const ListTile(
                    leading: Icon(
                      Icons.person_off_outlined,
                      color: ThemeConstants.accentColor,
                    ),
                    title: Text(
                      'Local Mode',
                      style: TextStyle(color: ThemeConstants.starColor),
                    ),
                    subtitle: Text(
                      'Not signed in',
                      style: TextStyle(
                        color: Color(0x99E8EAF6),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: ThemeConstants.accentColor,
                    ),
                    title: const Text(
                      'Free',
                      style: TextStyle(color: ThemeConstants.starColor),
                    ),
                    subtitle: Text(
                      'Limited to 2 black holes',
                      style: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Upgrade section (free users only)
          if (user?.tier == UserTier.free || user == null) ...[
            _SectionHeader(title: 'Upgrade'),
            Card(
              color: ThemeConstants.surfaceColor,
              child: ListTile(
                leading: const Icon(
                  Icons.rocket_launch_outlined,
                  color: ThemeConstants.wormholeColor,
                ),
                title: const Text(
                  'Upgrade to Paid',
                  style: TextStyle(color: ThemeConstants.starColor),
                ),
                subtitle: Text(
                  'Unlimited categories, wormholes, and more',
                  style: TextStyle(
                    color: ThemeConstants.starColor.withValues(alpha: 0.6),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: ThemeConstants.accentColor,
                  size: 16,
                ),
                onTap: () {
                  // TODO: launch upgrade flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upgrade coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Default color customization
          _SectionHeader(title: 'Default Colors'),
          _DefaultColorSection(context: context, ref: ref),
          const SizedBox(height: 16),

          // Sign out + account deletion
          if (user != null) ...[
            _SectionHeader(title: 'Account Actions'),
            Card(
              color: ThemeConstants.surfaceColor,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  Divider(
                    height: 1,
                    color: ThemeConstants.accentColor.withValues(alpha: 0.15),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(
                        color: ThemeConstants.starColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account deletion confirmation dialog
// ---------------------------------------------------------------------------

Future<void> _confirmDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ThemeConstants.surfaceColor,
      title: const Text(
        'Delete Account?',
        style: TextStyle(color: ThemeConstants.starColor),
      ),
      content: Text(
        'This will permanently delete your account and all associated data. '
        'This action cannot be undone.',
        style: TextStyle(
          color: ThemeConstants.starColor.withValues(alpha: 0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: ThemeConstants.accentColor.withValues(alpha: 0.8),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(authProvider.notifier).deleteAccount();
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Default color section widget
// ---------------------------------------------------------------------------

class _DefaultColorSection extends StatefulWidget {
  final BuildContext context;
  final WidgetRef ref;

  const _DefaultColorSection({
    required this.context,
    required this.ref,
  });

  @override
  State<_DefaultColorSection> createState() => _DefaultColorSectionState();
}

class _DefaultColorSectionState extends State<_DefaultColorSection> {
  late Box<dynamic> _box;

  @override
  void initState() {
    super.initState();
    _box = widget.ref.read(_prefsBoxProvider);
  }

  int get _bhColor =>
      _readColor(_box, _kDefaultBlackHoleColor, _defaultBlackHoleColorValue);
  int get _starColor =>
      _readColor(_box, _kDefaultStarColor, _defaultStarColorValue);
  int get _planetColor =>
      _readColor(_box, _kDefaultPlanetColor, _defaultPlanetColorValue);

  Future<void> _pickColor(
    String key,
    int currentValue,
    String label,
  ) async {
    final picked = await showColorPickerDialog(
      context,
      currentColor: currentValue,
    );
    if (picked != null) {
      await _box.put(key, picked);
      setState(() {});
    }
  }

  Future<void> _resetDefaults() async {
    await _box.put(_kDefaultBlackHoleColor, _defaultBlackHoleColorValue);
    await _box.put(_kDefaultStarColor, _defaultStarColorValue);
    await _box.put(_kDefaultPlanetColor, _defaultPlanetColorValue);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ThemeConstants.surfaceColor,
      child: Column(
        children: [
          _ColorSettingTile(
            label: 'Default Black Hole Color',
            color: Color(_bhColor),
            onTap: () => _pickColor(
              _kDefaultBlackHoleColor,
              _bhColor,
              'Default Black Hole Color',
            ),
          ),
          Divider(
            height: 1,
            color: ThemeConstants.accentColor.withValues(alpha: 0.15),
          ),
          _ColorSettingTile(
            label: 'Default Star Color',
            color: Color(_starColor),
            onTap: () => _pickColor(
              _kDefaultStarColor,
              _starColor,
              'Default Star Color',
            ),
          ),
          Divider(
            height: 1,
            color: ThemeConstants.accentColor.withValues(alpha: 0.15),
          ),
          _ColorSettingTile(
            label: 'Default Planet Color',
            color: Color(_planetColor),
            onTap: () => _pickColor(
              _kDefaultPlanetColor,
              _planetColor,
              'Default Planet Color',
            ),
          ),
          Divider(
            height: 1,
            color: ThemeConstants.accentColor.withValues(alpha: 0.15),
          ),
          ListTile(
            leading: const Icon(
              Icons.refresh,
              color: ThemeConstants.accentColor,
              size: 20,
            ),
            title: const Text(
              'Reset to Defaults',
              style: TextStyle(color: ThemeConstants.accentColor),
            ),
            onTap: _resetDefaults,
          ),
        ],
      ),
    );
  }
}

class _ColorSettingTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorSettingTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(color: ThemeConstants.starColor),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ThemeConstants.accentColor,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Section header (unchanged from original)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: ThemeConstants.accentColor.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
