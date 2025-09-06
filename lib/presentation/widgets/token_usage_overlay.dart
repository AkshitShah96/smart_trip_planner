import 'package:flutter/material.dart';
import '../pages/token_usage_page.dart';

class TokenUsageOverlay extends StatelessWidget {
  final int requestTokens;
  final int responseTokens;
  final int totalTokens;
  final bool isVisible;
  final VoidCallback? onToggle;

  const TokenUsageOverlay({
    super.key,
    required this.requestTokens,
    required this.responseTokens,
    required this.totalTokens,
    this.isVisible = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Token Usage',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onToggle != null)
                    Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTokenRow('Request', requestTokens, theme, Colors.blue),
              _buildTokenRow('Response', responseTokens, theme, Colors.green),
              _buildTokenRow('Total', totalTokens, theme, Colors.orange),
              const SizedBox(height: 4),
              _buildCostEstimate(theme),
              const SizedBox(height: 8),
              _buildViewDetailsButton(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenRow(String label, int tokens, ThemeData theme, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(tokens),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostEstimate(ThemeData theme) {
    final inputCost = (requestTokens / 1000) * 0.00015;
    final outputCost = (responseTokens / 1000) * 0.0006;
    final totalCost = inputCost + outputCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Est. Cost: \$${totalCost.toStringAsFixed(4)}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
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

  Widget _buildViewDetailsButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TokenUsagePage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          'View Details',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}




