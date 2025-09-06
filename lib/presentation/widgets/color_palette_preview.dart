import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget to preview the new unique color palette
class ColorPalettePreview extends StatelessWidget {
  const ColorPalettePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette Preview'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Primary Colors'),
            _buildColorRow([
              _buildColorCard('Primary Teal', AppTheme.primaryTeal),
              _buildColorCard('Light Teal', AppTheme.lightTeal),
              _buildColorCard('Dark Teal', AppTheme.darkTeal),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Accent Colors'),
            _buildColorRow([
              _buildColorCard('Coral', AppTheme.accentCoral),
              _buildColorCard('Purple', AppTheme.accentPurple),
              _buildColorCard('Gold', AppTheme.accentGold),
            ]),
            
            const SizedBox(height: 24),
            _buildColorRow([
              _buildColorCard('Mint', AppTheme.accentMint),
              _buildColorCard('Rose', AppTheme.accentRose),
              _buildColorCard('Info Blue', AppTheme.infoBlue),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Status Colors'),
            _buildColorRow([
              _buildColorCard('Success', AppTheme.successGreen),
              _buildColorCard('Warning', AppTheme.warningAmber),
              _buildColorCard('Error', AppTheme.errorRed),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Gradients'),
            _buildGradientPreview('Primary Gradient', AppTheme.primaryGradient),
            const SizedBox(height: 16),
            _buildGradientPreview('Teal-Coral Gradient', AppTheme.tealCoralGradient),
            const SizedBox(height: 16),
            _buildGradientPreview('Ocean Gradient', AppTheme.oceanGradient),
            const SizedBox(height: 16),
            _buildGradientPreview('Sunset Gradient', AppTheme.sunsetGradient),
            const SizedBox(height: 16),
            _buildGradientPreview('Tropical Gradient', AppTheme.tropicalGradient),
            const SizedBox(height: 16),
            _buildGradientPreview('Aurora Gradient', AppTheme.auroraGradient),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Sample Components'),
            _buildComponentPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildColorRow(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _buildColorCard(String name, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientPreview(String name, LinearGradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
        ),
      ],
    );
  }

  Widget _buildComponentPreview() {
    return Column(
      children: [
        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal),
                ),
                child: const Text('Outlined Button'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Cards
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sample Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a sample card with the new color scheme.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTeal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Teal Tag',
                        style: TextStyle(
                          color: AppTheme.darkTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightCoral,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Coral Tag',
                        style: TextStyle(
                          color: AppTheme.accentCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Floating Action Button
        Align(
          alignment: Alignment.centerRight,
          child: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

