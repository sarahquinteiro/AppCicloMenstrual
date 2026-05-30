import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cycle_entry.dart';

class CycleCard extends StatelessWidget {
  final CycleEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CycleCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.water_drop,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Início: ${fmt.format(entry.startDate)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.endDate != null)
                        Text(
                          'Fim: ${fmt.format(entry.endDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
            if (entry.cycleLength != null || entry.periodLength != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (entry.cycleLength != null)
                    _InfoChip(
                      icon: Icons.loop,
                      label: '${entry.cycleLength} dias de ciclo',
                      color: theme.colorScheme.secondary,
                    ),
                  if (entry.periodLength != null)
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: '${entry.periodLength} dias de período',
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),
            ],
            if (entry.mood != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_moodEmoji(entry.mood!), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    entry.mood!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (entry.symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.symptoms
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withOpacity(0.5),
                        ))
                    .toList(),
              ),
            ],
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _moodEmoji(String mood) {
    const map = {
      'Feliz': '😊',
      'Triste': '😢',
      'Irritada': '😠',
      'Ansiosa': '😰',
      'Cansada': '😴',
      'Normal': '😐',
    };
    return map[mood] ?? '😐';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
