import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/tool_call.dart';

class ToolAccordion extends StatefulWidget {
  final ToolCall toolCall;

  const ToolAccordion({
    super.key,
    required this.toolCall,
  });

  @override
  State<ToolAccordion> createState() => _ToolAccordionState();
}

class _ToolAccordionState extends State<ToolAccordion> {
  bool _isExpanded = false;

  IconData _getToolIcon(String tool) {
    switch (tool.toLowerCase()) {
      case 'terminal':
      case 'bash':
        return LucideIcons.terminal;
      case 'read_file':
      case 'search_files':
        return LucideIcons.fileSearch;
      case 'write_file':
      case 'patch':
        return LucideIcons.fileEdit;
      case 'web_search':
      case 'web_extract':
        return LucideIcons.globe;
      default:
        return LucideIcons.wrench;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.toolCall;
    final isRunning = tool.status == ToolExecutionStatus.running;
    final isError = tool.status == ToolExecutionStatus.error;

    final Color statusColor = isRunning
        ? AppColors.thinking
        : isError
            ? AppColors.error
            : AppColors.ok;

    final String statusLabel = isRunning
        ? 'RUNNING'
        : isError
            ? 'FAILED'
            : 'DONE';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: isRunning ? AppColors.thinking.withAlpha(100) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsed Header Bar (1 line, thumb-friendly)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppSpacing.roundedSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _getToolIcon(tool.tool),
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tool.tool.toUpperCase(),
                    style: AppTypography.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (tool.durationMs != null)
                    Text(
                      '${tool.durationMs}ms',
                      style: AppTypography.mono(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  const Spacer(),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: statusColor.withAlpha(120), width: 0.5),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTypography.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details (stdout, arguments)
          if (_isExpanded) ...[
            const Divider(color: AppColors.border, height: 1),
            Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tool.args.isNotEmpty) ...[
                    Text(
                      'INPUT ARGS:',
                      style: AppTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      tool.args.toString(),
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STDOUT / RESULT:',
                        style: AppTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (tool.output != null && tool.output!.isNotEmpty)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tool.output!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied output to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(
                            LucideIcons.copy,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    tool.output?.isNotEmpty == true
                        ? tool.output!
                        : (isRunning ? 'Executing tool in host daemon...' : 'No output produced.'),
                    style: AppTypography.mono(
                      fontSize: 11,
                      color: isError ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
