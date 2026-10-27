import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../providers/onboarding_draft.dart';

class _TourPage {
  const _TourPage(this.icon, this.title, this.subtitle, this.description);

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
}

const _pages = [
  _TourPage(
    Icons.home_outlined,
    'Home',
    'Your rental command center',
    'See your rental status, upcoming bills, recent activity, and everything happening with your property — all in one place.',
  ),
  _TourPage(
    Icons.payments_outlined,
    'Payments',
    'Track every shilling',
    'View your bills, payment history, and contributions. Every payment is recorded and traceable.',
  ),
  _TourPage(
    Icons.people_outline,
    'Household',
    'Shared rental awareness',
    'Connect with people you share your rental with. See activity, contributions, and stay in sync — without assigning who owes what.',
  ),
  _TourPage(
    Icons.notifications_outlined,
    'Activity',
    'Stay updated',
    'A unified timeline of everything important — payments, maintenance updates, new household members, and more.',
  ),
  _TourPage(
    Icons.person_outline,
    'Account',
    'Your identity center',
    'Manage your identity, roles, rental passport, privacy settings, and security — all from one place.',
  ),
];

class AppTourScreen extends ConsumerStatefulWidget {
  const AppTourScreen({super.key});

  @override
  ConsumerState<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends ConsumerState<AppTourScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: AppMotion.slow, curve: AppMotion.curve);
    }
  }

  void _finish() {
    ref.read(onboardingDraftProvider.notifier).clear();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: AppTextButton(
                  label: 'Skip',
                  color: AppColors.textSecondary,
                  onPressed: _finish,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _TourPageView(page: _pages[i]),
              ),
            ),
            Semantics(
              label: 'Page ${_page + 1} of ${_pages.length}',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: AppMotion.slow,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                        ),
                        width: i == _page ? AppSpacing.md : AppSpacing.xs,
                        height: AppSpacing.xs,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(AppSpacing.xxs),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryButton(
                label: _isLast ? 'Get Started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourPageView extends StatelessWidget {
  const _TourPageView({required this.page});

  final _TourPage page;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: page.icon,
              size: AppSpacing.xxxl + AppSpacing.lg,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(page.title, style: AppTypography.display),
            const SizedBox(height: AppSpacing.xs),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.subheading.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}
