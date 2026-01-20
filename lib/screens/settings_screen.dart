import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/settings_provider.dart';
import '../services/window_service.dart';

/// 全局设置页面
class SettingsScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const SettingsScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _hasChanges = false;

  static const String _geminiApiKeyUrl =
      'https://ai.google.dev/gemini-api/docs/api-key';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SettingsProvider>();
      if (provider.geminiApiKey != null) {
        _apiKeyController.text = provider.geminiApiKey!;
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final provider = context.read<SettingsProvider>();
    final success = await provider.saveGeminiApiKey(_apiKeyController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'API Key 已保存' : '保存失败'),
          backgroundColor: success
              ? AppTheme.highlightColor
              : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      if (success) {
        setState(() => _hasChanges = false);
      }
    }
  }

  Future<void> _clearApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('确认清除', style: TextStyle(color: AppTheme.textColor)),
        content: const Text(
          '确定要清除 API Key 吗？清除后需要重新输入才能使用 AI 功能。',
          style: TextStyle(color: AppTheme.secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      await provider.clearApiKey();
      _apiKeyController.clear();
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key 已清除'),
            backgroundColor: AppTheme.highlightColor,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _openApiKeyUrl() async {
    final uri = Uri.parse(_geminiApiKeyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(child: _buildSettingsContent()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (widget.isStandaloneWindow) {
              WindowService.instance.closeCurrentWindow();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(
            widget.isStandaloneWindow ? Icons.close : Icons.arrow_back_rounded,
          ),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.secondaryColor,
            backgroundColor: AppTheme.cardBg,
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.settings,
            color: AppTheme.accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'API 配置与应用设置',
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gemini API Key 设置
            _buildSection(
              title: 'Gemini API',
              icon: Icons.auto_awesome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '输入您的 Google AI Studio API Key 以使用 AI 图片修改功能',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // API Key 输入框
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = value != (provider.geminiApiKey ?? '');
                      });
                    },
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: '请输入 API Key',
                      hintStyle: TextStyle(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppTheme.primaryBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.accentColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppTheme.secondaryColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscureApiKey = !_obscureApiKey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 状态指示
                  Row(
                    children: [
                      Icon(
                        provider.hasApiKey
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 14,
                        color: provider.hasApiKey
                            ? AppTheme.highlightColor
                            : AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.hasApiKey ? 'API Key 已配置' : '未配置 API Key',
                        style: TextStyle(
                          color: provider.hasApiKey
                              ? AppTheme.highlightColor
                              : AppTheme.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading || !_hasChanges
                              ? null
                              : _saveSettings,
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: const Text('保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.accentColor
                                .withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: provider.hasApiKey ? _clearApiKey : null,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('清除'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBg,
                          foregroundColor: AppTheme.errorColor,
                          disabledForegroundColor: AppTheme.secondaryColor
                              .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 关于
            _buildSection(
              title: '关于',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('应用版本', '1.0.2'),
                  const SizedBox(height: 8),
                  _buildInfoRow('API 库', 'googleai_dart 3.0.0'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openApiKeyUrl,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '如何获取 Gemini API Key?',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
        ),
      ],
    );
  }
}
