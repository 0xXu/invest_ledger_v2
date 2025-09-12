import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_service.dart';
import '../core/auth/auth_state.dart';

import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/transactions/transactions_page.dart';
import '../presentation/pages/transactions/add_transaction_page.dart';
import '../presentation/pages/transactions/transaction_detail_page.dart';
import '../presentation/pages/transactions/edit_transaction_page.dart';
import '../presentation/pages/transactions/search_transactions_page.dart';
import '../presentation/pages/analytics/analytics_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/settings/version_settings_page.dart';
import '../presentation/pages/import_export/import_export_page.dart';
import '../presentation/auth/login_screen.dart';

import '../presentation/pages/auth/account_switcher_page.dart';
import '../presentation/pages/auth/quick_login_page.dart';
import '../presentation/auth/reset_password_screen.dart';
import '../core/auth/auth_guard.dart';
import '../presentation/pages/dev/dev_tools_page.dart';
import '../presentation/widgets/main_layout.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/quick-login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        redirect: (context, state) {
          // 检查认证状态，如果已登录则跳转到仪表板，否则跳转到快速登录
          final container = ProviderScope.containerOf(context);
          final authState = container.read(authServiceProvider);

          if (authState.status == AuthStatus.authenticated) {
            return '/dashboard';
          } else {
            return '/auth/quick-login';
          }
        },
      ),
      GoRoute(
        path: '/auth/quick-login',
        name: 'quick-login',
        builder: (context, state) => const QuickLoginPage(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthGuard(child: MainLayout(child: child)),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsPage(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-transaction',
                builder: (context, state) => const AddTransactionPage(),
              ),
              GoRoute(
                path: 'search',
                name: 'search-transactions',
                builder: (context, state) => const SearchTransactionsPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'transaction-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TransactionDetailPage(transactionId: id);
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'edit-transaction',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return EditTransactionPage(transactionId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'version',
                name: 'version-settings',
                builder: (context, state) => const VersionSettingsPage(),
              ),
              GoRoute(
                path: 'accounts',
                name: 'account-switcher',
                builder: (context, state) => const AccountSwitcherPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/import-export',
            name: 'import-export',
            builder: (context, state) => const ImportExportPage(),
          ),
         
          GoRoute(
            path: '/dev-tools',
            name: 'dev-tools',
            builder: (context, state) => const DevToolsPage(),
          ),
        ],
      ),
    ],
  );
});

// 导航状态管理
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}
