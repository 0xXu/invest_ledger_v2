import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/transactions/transactions_page.dart';
import '../presentation/pages/transactions/add_transaction_page.dart';
import '../presentation/pages/transactions/transaction_detail_page.dart';
import '../presentation/pages/transactions/edit_transaction_page.dart';
import '../presentation/pages/transactions/search_transactions_page.dart';
import '../presentation/pages/shared_investment/shared_investment_page.dart';
import '../presentation/pages/shared_investment/create_shared_investment_page.dart';
import '../presentation/pages/shared_investment/shared_investment_detail_page.dart';
import '../presentation/pages/shared_investment/edit_shared_investment_page.dart';
import '../presentation/pages/analytics/analytics_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/settings/version_settings_page.dart';
import '../presentation/pages/import_export/import_export_page.dart';
import '../presentation/auth/login_screen.dart';

import '../presentation/pages/auth/account_switcher_page.dart';
import '../presentation/auth/reset_password_screen.dart';
import '../core/auth/auth_guard.dart';
import '../presentation/pages/dev/dev_tools_page.dart';
import '../presentation/pages/common/under_development_page.dart';
import '../presentation/pages/ai_assistant/stock_analysis_page.dart';
import '../presentation/pages/ai_assistant/ai_suggestions_page.dart';
import '../presentation/pages/ai_assistant/suggestion_detail_page.dart';
import '../presentation/pages/ai_assistant/backtest_page.dart';
import '../presentation/pages/ai_analysis/ai_analysis_page.dart';
import '../presentation/pages/ai_analysis/ai_config_page.dart';
import '../presentation/pages/ai_analysis/analysis_history_page.dart';
import '../presentation/widgets/main_layout.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/auth/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final email = extra['email'] as String;
          final token = extra['token'] as String;

          return ResetPasswordScreen(
            email: email,
            token: token,
          );
        },
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
            path: '/shared-investment',
            name: 'shared-investment',
            builder: (context, state) => const SharedInvestmentPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-shared-investment',
                builder: (context, state) => const CreateSharedInvestmentPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'shared-investment-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SharedInvestmentDetailPage(sharedInvestmentId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-shared-investment',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EditSharedInvestmentPage(sharedInvestmentId: id);
                    },
                  ),
                ],
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
            path: '/ai-assistant',
            name: 'ai-assistant',
            builder: (context, state) => const UnderDevelopmentPage(
              title: 'AI投资助手',
              subtitle: 'AI投资助手功能正在紧张开发中\n敬请期待更多智能投资分析功能',
              icon: LucideIcons.bot,
              upcomingFeatures: [
                'AI股票分析 - 智能分析股票投资机会',
                'AI回测分析 - 回测投资策略表现',
                'AI投资建议 - 个性化投资建议推荐',
                '分析历史 - 查看历史分析记录',
                'AI配置 - 配置AI服务参数',
              ],
            ),
            routes: [
              GoRoute(
                path: 'stock-analysis',
                name: 'stock-analysis',
                builder: (context, state) => const StockAnalysisPage(),
              ),
              GoRoute(
                path: 'analysis',
                name: 'ai-analysis',
                builder: (context, state) => const AIAnalysisPage(),
              ),
              GoRoute(
                path: 'backtest',
                name: 'ai-backtest',
                builder: (context, state) => const BacktestPage(),
              ),
              GoRoute(
                path: 'suggestions',
                name: 'ai-suggestions',
                builder: (context, state) => const AISuggestionsPage(),
              ),
              GoRoute(
                path: 'suggestion/:id',
                name: 'suggestion-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SuggestionDetailPage(suggestionId: id);
                },
              ),
              GoRoute(
                path: 'config',
                name: 'ai-config',
                builder: (context, state) => const AIConfigPage(),
              ),
              GoRoute(
                path: 'history',
                name: 'ai-history',
                builder: (context, state) => const AnalysisHistoryPage(),
              ),
            ],
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
