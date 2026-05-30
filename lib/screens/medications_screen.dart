// ============================================================
// MEDICATIONS SCREEN — Lista de medicamentos da usuária
//
// Exibe duas seções:
//   - Em uso   (active = true)
//   - Pausados (active = false)
//
// Ações disponíveis: criar, editar, pausar/retomar, excluir.
// ============================================================

import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import 'medication_form_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _medService = MedicationService();

  List<Medication> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Busca todos os medicamentos do banco e atualiza a tela
  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _medService.getMedications();
      if (mounted) setState(() => _medications = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Alterna entre ativo/pausado sem abrir o formulário
  Future<void> _alternarAtivo(Medication med) async {
    try {
      await _medService.toggleActive(med.id!, !med.active);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // Confirmação e exclusão de um medicamento
  Future<void> _excluir(Medication med) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir medicamento'),
        content: Text('Deseja excluir "${med.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _medService.deleteMedication(med.id!);
        _carregar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  // Abre o formulário para criar ([med] null) ou editar ([med] preenchido)
  Future<void> _abrirFormulario([Medication? med]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MedicationFormScreen(medication: med)),
    );
    _carregar(); // recarrega após voltar
  }

  @override
  Widget build(BuildContext context) {
    // Separa a lista em duas seções
    final ativos   = _medications.where((m) => m.active).toList();
    final pausados = _medications.where((m) => !m.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _medications.isEmpty
                  ? _EstadoVazio(onAdd: () => _abrirFormulario())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Em uso ────────────────────────
                        if (ativos.isNotEmpty) ...[
                          _TituloSecao(
                              titulo: 'Em uso',
                              quantidade: ativos.length,
                              cor: Colors.green),
                          const SizedBox(height: 8),
                          ...ativos.map((m) => _MedicationCard(
                                medication: m,
                                onEdit:   () => _abrirFormulario(m),
                                onDelete: () => _excluir(m),
                                onToggle: () => _alternarAtivo(m),
                              )),
                          const SizedBox(height: 24),
                        ],
                        // ── Pausados ──────────────────────
                        if (pausados.isNotEmpty) ...[
                          _TituloSecao(
                              titulo: 'Pausados',
                              quantidade: pausados.length,
                              cor: Colors.grey),
                          const SizedBox(height: 8),
                          ...pausados.map((m) => _MedicationCard(
                                medication: m,
                                onEdit:   () => _abrirFormulario(m),
                                onDelete: () => _excluir(m),
                                onToggle: () => _alternarAtivo(m),
                              )),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}

// ── Título de seção com bolinha colorida e contador ─────────
class _TituloSecao extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final Color cor;

  const _TituloSecao(
      {required this.titulo, required this.quantidade, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Text('$quantidade',
              style: TextStyle(
                  fontSize: 12, color: cor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── Card de um medicamento na lista ─────────────────────────
class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  // Cor e ícone de acordo com o tipo do medicamento
  // Para adicionar ícones a novos tipos, inclua aqui
  (Color, IconData) get _tipoVisual {
    switch (medication.type) {
      case 'Anticoncepcional':  return (Colors.pink,   Icons.favorite_outline);
      case 'Analgésico':        return (Colors.orange, Icons.healing_outlined);
      case 'Anti-inflamatório': return (Colors.red,    Icons.local_pharmacy_outlined);
      case 'Suplemento':        return (Colors.green,  Icons.eco_outlined);
      case 'Hormônio':          return (Colors.purple, Icons.science_outlined);
      default:                  return (Colors.blue,   Icons.medication_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (cor, icone) = _tipoVisual;
    final inativo = !medication.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: inativo
          ? Colors.grey.shade50
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Ícone do tipo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: cor.withOpacity(inativo ? 0.06 : 0.12),
                  shape: BoxShape.circle),
              child: Icon(icone,
                  color: inativo ? Colors.grey : cor, size: 22),
            ),
            const SizedBox(width: 12),
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: inativo ? Colors.grey : null,
                      // risco no nome quando pausado
                      decoration: inativo ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      medication.type,
                      if (medication.dosage != null) medication.dosage!,
                    ].join(' • '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (medication.time != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(medication.time!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  ],
                ],
              ),
            ),
            // Menu de ações
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Colors.grey.shade400, size: 20),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      medication.active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(medication.active ? 'Pausar' : 'Retomar'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
              onSelected: (v) {
                if (v == 'edit')   onEdit();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tela de lista vazia ──────────────────────────────────────
class _EstadoVazio extends StatelessWidget {
  final VoidCallback onAdd;
  const _EstadoVazio({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhum medicamento cadastrado',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Adicione seus anticoncepcionais,\nanalgésicos e suplementos aqui.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
