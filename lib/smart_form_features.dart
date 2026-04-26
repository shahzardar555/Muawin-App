import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/register_provider.dart';

/// Smart form features UI components

/// Draft restoration dialog
class DraftRestoreDialog extends StatelessWidget {
  const DraftRestoreDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Text(
            'Restore Draft?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found a saved draft of your registration.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (provider.lastSaved != null)
                Text(
                  'Last saved: ${_formatDate(provider.lastSaved!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Would you like to restore your previous work?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearDraft();
                Navigator.of(context).pop();
              },
              child: Text(
                'Start Fresh',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.restoreDraft();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Restore Draft',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Form progress indicator
class FormProgressIndicator extends StatelessWidget {
  const FormProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${(provider.completionPercentage * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: provider.completionPercentage,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.timeSpent != null)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Time spent: ${_formatDuration(provider.timeSpent!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Autosave status indicator
class AutosaveStatusIndicator extends StatelessWidget {
  const AutosaveStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: provider.hasDraft
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: provider.hasDraft
                ? Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.hasDraft) ...[
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  provider.lastSaved != null
                      ? 'Autosaved ${_formatLastSave(provider.lastSaved!)}'
                      : 'Draft saved',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Autosave enabled',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatLastSave(DateTime lastSaved) {
    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// Form completion insights
class FormCompletionInsights extends StatelessWidget {
  const FormCompletionInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Form Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInsightRow(
                context,
                'Completion Rate',
                '${(provider.completionPercentage * 100).toInt()}%',
                Icons.trending_up,
                provider.completionPercentage > 0.5,
              ),
              const SizedBox(height: 8),
              _buildInsightRow(
                context,
                'Time Spent',
                provider.timeSpent != null
                    ? _formatDuration(provider.timeSpent!)
                    : 'Not started',
                Icons.access_time,
                true,
              ),
              const SizedBox(height: 8),
              _buildInsightRow(
                context,
                'Current Step',
                'Step ${provider.currentStep} of ${provider.totalSteps}',
                Icons.flag,
                true,
              ),
              if (provider.hasUnsavedChanges) ...[
                const SizedBox(height: 8),
                _buildInsightRow(
                  context,
                  'Status',
                  'Unsaved changes',
                  Icons.edit,
                  false,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isPositive,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPositive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPositive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Smart form toolbar
class SmartFormToolbar extends StatelessWidget {
  const SmartFormToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(child: AutosaveStatusIndicator()),
          const SizedBox(width: 16),
          Consumer<RegisterProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'restore_draft':
                      if (provider.hasDraft) {
                        _showRestoreDialog(context);
                      }
                      break;
                    case 'clear_draft':
                      _showClearDraftDialog(context);
                      break;
                    case 'view_insights':
                      _showInsightsDialog(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (provider.hasDraft)
                    PopupMenuItem(
                      value: 'restore_draft',
                      child: Row(
                        children: [
                          const Icon(Icons.restore),
                          const SizedBox(width: 8),
                          Text(
                            'Restore Draft',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  if (provider.hasDraft)
                    PopupMenuItem(
                      value: 'clear_draft',
                      child: Row(
                        children: [
                          const Icon(Icons.clear),
                          const SizedBox(width: 8),
                          Text(
                            'Clear Draft',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'view_insights',
                    child: Row(
                      children: [
                        const Icon(Icons.insights),
                        const SizedBox(width: 8),
                        Text(
                          'View Insights',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DraftRestoreDialog(),
    );
  }

  void _showClearDraftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Draft?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to clear the saved draft? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<RegisterProvider>(context, listen: false)
                  .clearDraft();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear Draft',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsightsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FormCompletionInsights(),
            ],
          ),
        ),
      ),
    );
  }
}
