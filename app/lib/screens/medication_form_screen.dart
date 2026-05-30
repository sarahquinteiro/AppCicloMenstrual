// ============================================================
// MEDICATION FORM SCREEN — Criar ou editar um medicamento
//
// Recebe um [medication] opcional:
//   - null      → criando um novo medicamento
//   - preenchido → editando um existente
// ============================================================

import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/auth_service.dart';

class MedicationFormScreen extends StatefulWidget {
  final Medication? medication;

  const MedicationFormScreen({super.key, this.medication});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _medService = MedicationService();
  final _authService = AuthService();

  final _nameController   = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController  = TextEditingController();

  String  _selectedType = 'Anticoncepcional';
  String? _selectedTime;
  bool    _active = true;
  bool    _isSaving = false;

  // ── Tipos de medicamento disponíveis ──────────────────────
  // Para adicionar um novo tipo: inclua aqui e no banco SQL
  static const List<String> _types = [
    'Anticoncepcional',
    'Analgésico',
    'Anti-inflamatório',
    'Suplemento',
    'Hormônio',
    'Outro',
  ];

  // ── Horários disponíveis (intervalos de 30 min) ──────────
  static const List<String> _times = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }

  // Preenche os campos quando é edição
  void _preencherCampos() {
    if (widget.medication != null) {
      final m = widget.medication!;
      _nameController.text   = m.name;
      _dosageController.text = m.dosage ?? '';
      _notesController.text  = m.notes ?? '';
      _selectedType = m.type;
      _selectedTime = m.time;
      _active       = m.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Salva ou atualiza o medicamento
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final med = Medication(
        id:     widget.medication?.id,   // null = novo, preenchido = atualiza
        userId: _authService.currentUser!.id,
        name:   _nameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        time:   _selectedTime,
        type:   _selectedType,
        active: _active,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Decide entre criar novo ou atualizar existente
      if (widget.medication == null) {
        await _medService.createMedication(med);  // CRIAR
      } else {
        await _medService.updateMedication(med);  // ATUALIZAR
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.medication == null
        ? 'Novo medicamento'
        : 'Editar medicamento';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Nome ──────────────────────────────────────
            _Label('Nome do medicamento *'),
            TextFormField(
              controller: _nameController,
              decoration: _dec('Ex: Diane 35, Ibuprofeno...'),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o nome do medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Tipo ──────────────────────────────────────
            _Label('Tipo'),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _dec(null),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),

            // ── Dosagem ───────────────────────────────────
            _Label('Dosagem (opcional)'),
            TextFormField(
              controller: _dosageController,
              decoration: _dec('Ex: 1 comprimido, 500mg, 2 gotas...'),
            ),
            const SizedBox(height: 16),

            // ── Horário ───────────────────────────────────
            _Label('Horário de tomar (opcional)'),
            DropdownButtonFormField<String>(
              value: _selectedTime,
              decoration: _dec('Selecione o horário'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sem horário fixo',
                      style: TextStyle(color: Colors.grey)),
                ),
                ..._times.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _selectedTime = v),
            ),
            const SizedBox(height: 16),

            // ── Status (só aparece na edição) ─────────────
            if (widget.medication != null) ...[
              _Label('Status'),
              SwitchListTile(
                value: _active,
                title: Text(_active ? 'Em uso' : 'Pausado'),
                subtitle: Text(
                  _active
                      ? 'Você está tomando este medicamento'
                      : 'Você parou de tomar este medicamento',
                  style: const TextStyle(fontSize: 12),
                ),
                onChanged: (v) => setState(() => _active = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ],

            // ── Anotações ─────────────────────────────────
            _Label('Anotações (opcional)'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: _dec('Ex: tomar com água, não tomar em jejum...'),
            ),
            const SizedBox(height: 32),

            // ── Botão salvar ──────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _salvar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Decoração padrão dos campos do formulário
  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );
}

// Label acima de cada campo
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
