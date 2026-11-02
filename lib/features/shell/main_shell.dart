import 'package:flutter/material.dart';

import '../../core/icons/sw_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../app.dart';
import '../../data/app_state.dart';
import '../home/home_screen.dart';
import '../outfits/outfits_screen.dart';
import '../profile/profile_screen.dart';
import '../stylist/stylist_desk_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

/// The five destinations of the bottom navigation bar.
enum ShellTab { home, wardrobe, stylist, outfits, profile }

/// Bottom navigation host.
///
/// Each tab owns an independent [Navigator] so pushed detail screens keep their
/// own history while the user moves between destinations.
///
/// The whole shell is gated on a live session: a signed-out user (for example
/// after the token was rejected server-side) is bounced to Login, and the
/// shell route is removed from the stack behind them.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = ShellTab.home});

  final ShellTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late ShellTab _tab = widget.initialTab;

  late final Map<ShellTab, GlobalKey<NavigatorState>> _keys = {
    for (final tab in ShellTab.values) tab: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requireAuth());
  }

  /// Sends unauthenticated visitors back to Login without leaving the shell
  /// behind them in the back stack.
  void _requireAuth() {
    if (!mounted || AppState.instance.isAuthenticated) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  void _select(ShellTab tab) {
    if (tab == _tab) {
      // Tapping the active tab pops that stack back to its root.
      _keys[tab]?.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _tab = tab);
  }

  void _goToRoot() {
    _keys[_tab]?.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[_tab]?.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_tab != ShellTab.home) {
          setState(() => _tab = ShellTab.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            for (final tab in ShellTab.values)
              Offstage(
                offstage: _tab != tab,
                child: TickerMode(
                  enabled: _tab == tab,
                  child: _TabNavigator(
                    navigatorKey: _keys[tab]!,
                    tab: tab,
                    onOpenTab: _select,
                    onOpenRoot: _goToRoot,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SwBottomNav(current: _tab, onSelect: _select),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.tab,
    required this.onOpenTab,
    required this.onOpenRoot,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ShellTab tab;
  final ValueChanged<ShellTab> onOpenTab;
  final VoidCallback onOpenRoot;

  Widget _root() => switch (tab) {
    ShellTab.home => HomeScreen(onOpenTab: onOpenTab),
    ShellTab.wardrobe => const WardrobeScreen(),
    ShellTab.stylist => const StylistDeskScreen(),
    ShellTab.outfits => const OutfitsScreen(),
    ShellTab.profile => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => _root()),
    );
  }
}

/// The persistent five item tab bar.
class SwBottomNav extends StatelessWidget {
  const SwBottomNav({super.key, required this.current, required this.onSelect});

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  static const List<(ShellTab, SwIcon, String)> _items = [
    (ShellTab.home, SwIcon.home, 'Home'),
    (ShellTab.wardrobe, SwIcon.shirt, 'Wardrobe'),
    (ShellTab.stylist, SwIcon.sparkle, 'AI Stylist'),
    (ShellTab.outfits, SwIcon.layers, 'Outfits'),
    (ShellTab.profile, SwIcon.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.navBar,
          child: Row(
            children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: _NavItem(
                    icon: icon,
                    label: label,
                    active: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final SwIcon icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwIconView(icon, size: Sizes.navIcon, color: color, strokeWidth: 1.6),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: active ? AppText.navLabelActive : AppText.navLabel,
          ),
        ],
      ),
    );
  }
}
