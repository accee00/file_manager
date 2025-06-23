import 'package:file_manager2/features/clean/presentation/widget/app_grid_item.dart';
import 'package:file_manager2/features/clean/presentation/widget/app_list_item.dart';
import 'package:file_manager2/features/clean/presentation/widget/uninstall_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with TickerProviderStateMixin {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fabAnimationController;
  late final AnimationController _listAnimationController;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      setState(() {
        _apps = apps
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        _filteredApps = _apps;
        _isLoading = false;
      });

      if (mounted) {
        _fabAnimationController.forward();
        _listAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load apps. Please check permissions and try again.";
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredApps = _apps;
      } else {
        _filteredApps = _apps
            .where(
              (app) =>
                  app.name.toLowerCase().contains(query.toLowerCase()) ||
                  app.packageName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _toggleViewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Installed Apps',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.1),
                      colorScheme.secondaryContainer.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              AnimatedBuilder(
                animation: _fabAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabAnimationController.value,
                    child: IconButton(
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                      ),
                      onPressed: _toggleViewMode,
                      tooltip: _isGridView ? 'List View' : 'Grid View',
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search apps...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _filterApps('');
                            },
                          ),
                        ]
                      : null,
                  onChanged: _filterApps,
                  elevation: MaterialStateProperty.all(2),
                  backgroundColor: MaterialStateProperty.all(
                    colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildMessage(
        icon: Icons.hourglass_top_rounded,
        title: 'Loading apps...',
        subtitle: '',
        showSpinner: true,
      );
    }

    if (_error != null) {
      return _buildMessage(
        icon: Icons.error_outline_rounded,
        title: 'Oops!',
        subtitle: _error!,
        action: FilledButton.icon(
          onPressed: _loadApps,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      );
    }

    if (_filteredApps.isEmpty) {
      return _buildMessage(
        icon: _searchQuery.isEmpty
            ? Icons.apps_rounded
            : Icons.search_off_rounded,
        title: _searchQuery.isEmpty ? 'No apps found' : 'No matching apps',
        subtitle: _searchQuery.isEmpty
            ? 'It looks like there are no installed apps to display.'
            : 'Try adjusting your search terms.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filteredApps.length} app${_filteredApps.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: _loadApps,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final animation = _buildAnimation(index);
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: Opacity(
              opacity: animation.value,
              child: AppListItem(
                app: _filteredApps[index],
                onOpen: () => _openApp(_filteredApps[index]),
                onSettings: () => _openSettings(_filteredApps[index]),
                onUninstall: () =>
                    _confirmUninstall(context, _filteredApps[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      key: const ValueKey('grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final animation = _buildAnimation(index);
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: AppGridItem(
                app: _filteredApps[index],
                onOpen: () => _openApp(_filteredApps[index]),
                onSettings: () => _openSettings(_filteredApps[index]),
                onUninstall: () =>
                    _confirmUninstall(context, _filteredApps[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Animation<double> _buildAnimation(int index) {
    final delay = (index * 0.1).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showSpinner = false,
    Widget? action,
  }) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showSpinner)
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                Icon(
                  icon,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 24), action],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openApp(AppInfo app) async {
    HapticFeedback.selectionClick();
    try {
      await InstalledApps.startApp(app.packageName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open ${app.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openSettings(AppInfo app) async {
    HapticFeedback.selectionClick();
    try {
      await InstalledApps.openSettings(app.packageName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open settings for ${app.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmUninstall(BuildContext context, AppInfo app) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => UninstallConfirmationDialog(appName: app.name),
    );

    if (confirmed == true) {
      try {
        final result = await InstalledApps.uninstallApp(app.packageName);
        if (result != null && mounted) {
          await _loadApps();
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${app.name} has been uninstalled'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to uninstall ${app.name}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
