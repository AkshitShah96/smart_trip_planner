import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_key_tester.dart';
import '../../core/services/api_config_service.dart';
import '../../core/theme/app_theme.dart';

class ApiKeyTestPage extends ConsumerStatefulWidget {
  const ApiKeyTestPage({super.key});

  @override
  ConsumerState<ApiKeyTestPage> createState() => _ApiKeyTestPageState();
}

class _ApiKeyTestPageState extends ConsumerState<ApiKeyTestPage> {
  final List<String> _apiKeys = [
    'sk-abcdef1234567890abcdef1234567890abcdef12',
    'sk-1234567890abcdef1234567890abcdef12345678',
    'sk-abcdefabcdefabcdefabcdefabcdefabcdef12',
    'sk-7890abcdef7890abcdef7890abcdef7890abcd',
    'sk-1234abcd1234abcd1234abcd1234abcd1234abcd',
    'sk-abcd1234abcd1234abcd1234abcd1234abcd1234',
    'sk-5678efgh5678efgh5678efgh5678efgh5678efgh',
    'sk-efgh5678efgh5678efgh5678efgh5678efgh5678',
    'sk-ijkl1234ijkl1234ijkl1234ijkl1234ijkl1234',
    'sk-mnop5678mnop5678mnop5678mnop5678mnop5678',
    'sk-qrst1234qrst1234qrst1234qrst1234qrst1234',
    'sk-uvwx5678uvwx5678uvwx5678uvwx5678uvwx5678',
    'sk-1234ijkl1234ijkl1234ijkl1234ijkl1234ijkl',
    'sk-5678mnop5678mnop5678mnop5678mnop5678mnop',
    'sk-qrst5678qrst5678qrst5678qrst5678qrst5678',
    'sk-uvwx1234uvwx1234uvwx1234uvwx1234uvwx1234',
    'sk-1234abcd5678efgh1234abcd5678efgh1234abcd',
    'sk-5678ijkl1234mnop5678ijkl1234mnop5678ijkl',
    'sk-abcdqrstefghuvwxabcdqrstefghuvwxabcdqrst',
    'sk-ijklmnop1234qrstijklmnop1234qrstijklmnop',
    'sk-1234uvwx5678abcd1234uvwx5678abcd1234uvwx',
    'sk-efghijkl5678mnopabcd1234efghijkl5678mnop',
    'sk-mnopqrstuvwxabcdmnopqrstuvwxabcdmnopqrst',
    'sk-ijklmnopqrstuvwxijklmnopqrstuvwxijklmnop',
    'sk-abcd1234efgh5678abcd1234efgh5678abcd1234',
    'sk-1234ijklmnop5678ijklmnop1234ijklmnop5678',
    'sk-qrstefghuvwxabcdqrstefghuvwxabcdqrstefgh',
    'sk-uvwxijklmnop1234uvwxijklmnop1234uvwxijkl',
    'sk-abcd5678efgh1234abcd5678efgh1234abcd5678',
    'sk-ijklmnopqrstuvwxijklmnopqrstuvwxijklmnop',
    'sk-1234qrstuvwxabcd1234qrstuvwxabcd1234qrst',
    'sk-efghijklmnop5678efghijklmnop5678efghijkl',
    'sk-mnopabcd1234efghmnopabcd1234efghmnopabcd',
    'sk-ijklqrst5678uvwxijklqrst5678uvwxijklqrst',
    'sk-1234ijkl5678mnop1234ijkl5678mnop1234ijkl',
    'sk-abcdqrstefgh5678abcdqrstefgh5678abcdqrst',
    'sk-ijklmnopuvwx1234ijklmnopuvwx1234ijklmnop',
    'sk-efgh5678abcd1234efgh5678abcd1234efgh5678',
    'sk-mnopqrstijkl5678mnopqrstijkl5678mnopqrst',
    'sk-1234uvwxabcd5678uvwxabcd1234uvwxabcd5678',
    'sk-ijklmnop5678efghijklmnop5678efghijklmnop',
    'sk-abcd1234qrstuvwxabcd1234qrstuvwxabcd1234',
    'sk-1234efgh5678ijkl1234efgh5678ijkl1234efgh',
    'sk-5678mnopqrstuvwx5678mnopqrstuvwx5678mnop',
    'sk-abcdijkl1234uvwxabcdijkl1234uvwxabcdijkl',
    'sk-ijklmnopabcd5678ijklmnopabcd5678ijklmnop',
    'sk-1234efghqrstuvwx1234efghqrstuvwx1234efgh',
    'sk-5678ijklmnopabcd5678ijklmnopabcd5678ijkl',
    'sk-abcd1234efgh5678abcd1234efgh5678abcd1234',
    'sk-ijklmnopqrstuvwxijklmnopqrstuvwxijklmnop',
  ];

  final ApiKeyTester _tester = ApiKeyTester();
  final ApiConfigService _configService = ApiConfigService();
  List<ApiKeyTestResult> _testResults = [];
  bool _isTesting = false;
  String? _selectedOpenAIKey;
  String? _selectedGeminiKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('API Key Testing'),
        backgroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTestButton(),
            const SizedBox(height: 24),
            if (_testResults.isNotEmpty) _buildResults(),
            const SizedBox(height: 24),
            if (_selectedOpenAIKey != null || _selectedGeminiKey != null) _buildConfiguration(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔑 API Key Testing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Testing ${_apiKeys.length} API keys to find working ones for OpenAI and Gemini',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isTesting ? null : _testAllKeys,
        icon: _isTesting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                ),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_isTesting ? 'Testing API Keys...' : 'Test All API Keys'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResults() {
    final workingKeys = _testResults.where((r) => r.isValid).toList();
    final failedKeys = _testResults.where((r) => !r.isValid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Results',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Working keys
        if (workingKeys.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Working API Keys (${workingKeys.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...workingKeys.map((result) => _buildWorkingKeyItem(result)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Failed keys summary
        if (failedKeys.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: AppTheme.errorRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Failed API Keys: ${failedKeys.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkingKeyItem(ApiKeyTestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result.provider == 'OpenAI' 
                  ? const Color(0xFF10A37F).withOpacity(0.1)
                  : const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result.provider,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: result.provider == 'OpenAI' 
                    ? const Color(0xFF10A37F)
                    : const Color(0xFF4285F4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.provider} API Key',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _selectKey(result),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            tooltip: 'Use this key',
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguration() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected API Keys',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedOpenAIKey != null) ...[
            _buildSelectedKeyItem('OpenAI', _selectedOpenAIKey!, 'Chat & Itinerary Generation'),
            const SizedBox(height: 12),
          ],
          
          if (_selectedGeminiKey != null) ...[
            _buildSelectedKeyItem('Gemini', _selectedGeminiKey!, 'Alternative AI Provider'),
            const SizedBox(height: 12),
          ],
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedKeyItem(String provider, String key, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: provider == 'OpenAI' 
                  ? const Color(0xFF10A37F).withOpacity(0.1)
                  : const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              provider,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: provider == 'OpenAI' 
                    ? const Color(0xFF10A37F)
                    : const Color(0xFF4285F4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${key.substring(0, 8)}...${key.substring(key.length - 8)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeKey(provider),
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Remove key',
          ),
        ],
      ),
    );
  }

  Future<void> _testAllKeys() async {
    setState(() {
      _isTesting = true;
      _testResults = [];
    });

    try {
      final results = await _tester.testMultipleKeys(_apiKeys);
      setState(() {
        _testResults = results;
        _isTesting = false;
      });

      // Show summary
      final workingCount = results.where((r) => r.isValid).length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found $workingCount working API keys out of ${_apiKeys.length}'),
            backgroundColor: workingCount > 0 ? const Color(0xFF4CAF50) : AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing API keys: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _selectKey(ApiKeyTestResult result) {
    setState(() {
      if (result.provider == 'OpenAI') {
        _selectedOpenAIKey = _apiKeys[_testResults.indexOf(result)];
      } else if (result.provider == 'Gemini') {
        _selectedGeminiKey = _apiKeys[_testResults.indexOf(result)];
      }
    });
  }

  void _removeKey(String provider) {
    setState(() {
      if (provider == 'OpenAI') {
        _selectedOpenAIKey = null;
      } else if (provider == 'Gemini') {
        _selectedGeminiKey = null;
      }
    });
  }

  Future<void> _saveConfiguration() async {
    try {
      if (_selectedOpenAIKey != null) {
        await _configService.saveOpenAIKey(_selectedOpenAIKey!);
      }
      
      if (_selectedGeminiKey != null) {
        await _configService.saveGeminiKey(_selectedGeminiKey!);
      }
      
      // Set preferred provider
      String preferredProvider = 'openai';
      if (_selectedOpenAIKey != null && _selectedGeminiKey == null) {
        preferredProvider = 'openai';
      } else if (_selectedGeminiKey != null && _selectedOpenAIKey == null) {
        preferredProvider = 'gemini';
      } else if (_selectedOpenAIKey != null && _selectedGeminiKey != null) {
        preferredProvider = 'openai'; // Default to OpenAI if both available
      }
      
      await _configService.setPreferredProvider(preferredProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API keys saved successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
