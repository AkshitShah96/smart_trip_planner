import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/token_usage_providers.dart';
import '../widgets/token_usage_overlay.dart';

class TokenUsagePage extends ConsumerWidget {
  const TokenUsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(tokenUsageProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Usage Analytics'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              tokenState.isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
              color: tokenState.isDebugMode ? theme.colorScheme.primary : null,
            ),
            onPressed: () => ref.read(tokenUsageProvider.notifier).toggleDebugMode(),
            tooltip: 'Toggle Debug Mode',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, ref),
            tooltip: 'Reset Usage',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(context, ref, tokenState),
            const SizedBox(height: 16),
            _buildSessionCard(context, ref, tokenState),
            const SizedBox(height: 16),
            _buildTotalUsageCard(context, ref, tokenState),
            const SizedBox(height: 16),
            _buildCostAnalysisCard(context, ref, tokenState),
            const SizedBox(height: 16),
            _buildUsageHistoryCard(context, ref, tokenState),
            const SizedBox(height: 16),
            _buildSettingsCard(context, ref, tokenState),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);
    final totalTokens = tokenState.totalUsage.totalTokens;
    final sessionTokens = tokenState.currentSession.totalTokens;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Usage Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Tokens',
                    totalTokens,
                    theme.colorScheme.primary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'This Session',
                    sessionTokens,
                    theme.colorScheme.secondary,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalTokens > 0 ? (sessionTokens / (totalTokens + sessionTokens)) : 0,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Session represents ${totalTokens > 0 ? ((sessionTokens / (totalTokens + sessionTokens)) * 100).toStringAsFixed(1) : '0'}% of total usage',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);
    final session = tokenState.currentSession;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Current Session',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTokenBreakdown(session, theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(tokenUsageProvider.notifier).resetCurrentSession(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalUsageCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);
    final total = tokenState.totalUsage;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Total Usage',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTokenBreakdown(total, theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetDialog(context, ref),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Reset All Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostAnalysisCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);
    final total = tokenState.totalUsage;
    
    // OpenAI GPT-4 pricing (approximate)
    const inputCostPer1K = 0.00015; // $0.15 per 1K tokens
    const outputCostPer1K = 0.0006;  // $0.60 per 1K tokens
    
    final inputCost = (total.requestTokens / 1000) * inputCostPer1K;
    final outputCost = (total.responseTokens / 1000) * outputCostPer1K;
    final totalCost = inputCost + outputCost;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Cost Analysis',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCostItem(
                    'Input Cost',
                    '\$${inputCost.toStringAsFixed(4)}',
                    theme.colorScheme.primary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildCostItem(
                    'Output Cost',
                    '\$${outputCost.toStringAsFixed(4)}',
                    theme.colorScheme.secondary,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Estimated Cost',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalCost.toStringAsFixed(4)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '* Based on OpenAI GPT-4 pricing. Actual costs may vary.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageHistoryCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Usage Patterns',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPatternItem(
              'Average Request Size',
              '${tokenState.totalUsage.requestTokens > 0 ? (tokenState.totalUsage.requestTokens / 10).round() : 0} tokens',
              Icons.send,
              theme,
            ),
            const SizedBox(height: 8),
            _buildPatternItem(
              'Average Response Size',
              '${tokenState.totalUsage.responseTokens > 0 ? (tokenState.totalUsage.responseTokens / 10).round() : 0} tokens',
              Icons.reply,
              theme,
            ),
            const SizedBox(height: 8),
            _buildPatternItem(
              'Efficiency Ratio',
              '${tokenState.totalUsage.requestTokens > 0 ? (tokenState.totalUsage.responseTokens / tokenState.totalUsage.requestTokens).toStringAsFixed(2) : '0.00'}:1',
              Icons.trending_up,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref, TokenUsageState tokenState) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Show token usage overlay'),
              value: tokenState.isDebugMode,
              onChanged: (value) => ref.read(tokenUsageProvider.notifier).setDebugMode(value),
              secondary: Icon(
                tokenState.isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
                color: tokenState.isDebugMode ? theme.colorScheme.primary : null,
              ),
            ),
            SwitchListTile(
              title: const Text('Overlay Visible'),
              subtitle: const Text('Show floating token usage'),
              value: tokenState.isOverlayVisible,
              onChanged: (value) => ref.read(tokenUsageProvider.notifier).setOverlayVisible(value),
              secondary: Icon(
                tokenState.isOverlayVisible ? Icons.visibility : Icons.visibility_off,
                color: tokenState.isOverlayVisible ? theme.colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(value),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCostItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenBreakdown(TokenUsageData data, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTokenRow('Request Tokens', data.requestTokens, Colors.blue, theme),
            ),
            Expanded(
              child: _buildTokenRow('Response Tokens', data.responseTokens, Colors.green, theme),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTokenRow('Total Tokens', data.totalTokens, Colors.orange, theme),
      ],
    );
  }

  Widget _buildTokenRow(String label, int tokens, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            _formatNumber(tokens),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Usage Data'),
        content: const Text(
          'Are you sure you want to reset all token usage data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tokenUsageProvider.notifier).resetAllUsage();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usage data has been reset'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
