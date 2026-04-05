import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../pages/main_app_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniversalHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final double? expandedHeight;
  final Widget? bottom;
  final bool alignRight;
  final bool showBackButton;
  final bool showProfile;
  final String? backgroundImage;

  const UniversalHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon = Icons.dashboard,
    this.actions,
    this.expandedHeight,
    this.bottom,
    this.alignRight = false,
    this.showBackButton = false,
    this.showProfile = true,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // Premium Green Touch Colors
    final Color primaryGreen = AppTheme.primaryGreen;
    final Color softGreen = const Color(0xFF43A047);

    return SliverAppBar(
      expandedHeight: expandedHeight ?? (isDesktop ? 180 : 160),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.getAppBarColor(context),
      stretch: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? Center(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
            )
          : Builder(
              builder: (context) => Center(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),
              ),
            ),
      actions: [
        if (actions != null) ...actions!,
        if (showProfile) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Center(
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainAppLayout(initialIndex: 4)));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: user?.photoURL != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoURL!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: user?.photoURL == null
                      ? const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // REFINED GREEN TOUCH GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppTheme.darkSurface, AppTheme.darkBackground]
                      : [primaryGreen, softGreen],
                ),
              ),
            ),

            if (backgroundImage != null)
              Opacity(
                opacity: 0.1,
                child: Image.asset(backgroundImage!, fit: BoxFit.cover),
              ),

            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: alignRight
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!alignRight) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: isDesktop ? 32 : 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: alignRight
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: isDesktop ? 28 : 22,
                                      letterSpacing: -0.5,
                                    ),
                                textAlign: alignRight
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: isDesktop ? 14 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: alignRight
                                      ? TextAlign.right
                                      : TextAlign.left,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }
}
