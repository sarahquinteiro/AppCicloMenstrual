import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cycle_entry.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

// ============================================================
// TELA DE FORMULÁRIO (Criar ou Editar um ciclo)
//
// Recebe um [entry] opcional.
//   - Se [entry] for null  → estamos CRIANDO um novo registro
//   - Se [entry] tiver valor → estamos EDITANDO um registro existente
// ============================================================

class FormScreen extends StatefulWidget {
  final CycleEntry? entry; // null = novo, preenchido = edição

  const FormScreen({super.key, this.entry});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // Serviços usados nesta tela
  final _dbService = DatabaseService();
  final _authService = AuthService();

  // Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  // Controlador do campo "Anotações"
  final _notesController = TextEditingController();

  // ── Campos do formulário ──────────────────────────────────
  DateTime? _startDate;    // Data de início da menstruação
  DateTime? _endDate;      // Data de término (opcional)
  int _cycleLength = 28;   // Duração do ciclo em dias (padrão: 28)
  int _periodLength = 5;   // Duração do período em dias (padrão: 5)
  String? _mood;           // Humor selecionado
  List<String> _symptoms = []; // Sintomas marcados

  bool _isSaving = false; // controla o botão de salvar

  // ── Opções fixas de humor ─────────────────────────────────
  // Para adicionar novos humores, basta incluir aqui
  final List<String> _moodOptions = [
    'Feliz',
    'Triste',
    'Irritada',
    'Ansiosa',
    'Cansada',
    'Normal',
  ];

  // ── Opções fixas de sintomas ──────────────────────────────
  // Para adicionar novos sintomas, basta incluir aqui
  final List<String> _symptomOptions = [
    'Cólica',
    'Dor de cabeça',
    'Inchaço',
    'Náusea',
    'Acne',
    'Sensibilidade nos seios',
    'Fadiga',
    'Insônia',
  ];

  // ── Emojis de humor ───────────────────────────────────────
  final Map<String, String> _moodEmojis = {
    'Feliz': '😊',
    'Triste': '😢',
    'Irritada': '😠',
    'Ansiosa': '😰',
    'Cansada': '😴',
    'Normal': '😐',
  };

  @override
  void initState() {
    super.initState();
    _preencherCampos(); // preenche os campos caso seja edição
  }

  // Preenche os campos do formulário com os dados do registro existente
  void _preencherCampos() {
    if (widget.entry != null) {
      final e = widget.entry!;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _periodLength = e.periodLength ?? 5;
      _mood = e.mood;
      _symptoms = List.from(e.symptoms); // cópia para não alterar o original
      _notesController.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose(); // libera o controlador ao sair da tela
    super.dispose();
  }

  // ── Abre o seletor de data do sistema ────────────────────
  // [initial] = data pré-selecionada no calendário
  // [first]   = data mínima permitida
  // [last]    = data máxima permitida
  Future<DateTime?> _escolherData({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: const Locale('pt', 'BR'),
    );
  }

  // ── Salva ou atualiza o registro ─────────────────────────
  Future<void> _salvar() async {
    // 1. Valida os campos do formulário
    if (!_formKey.currentState!.validate()) return;

    // 2. Garante que a data de início foi preenchida
    if (_startDate == null) {
      _mostrarErro('Selecione a data de início da menstruação.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 3. Monta o objeto com os dados do formulário
      final entry = CycleEntry(
        id: widget.entry?.id, // null = novo, preenchido = atualização
        userId: _authService.currentUser!.id,
        startDate: _startDate!,
        endDate: _endDate,
        periodLength: _periodLength,
        mood: _mood,
        symptoms: _symptoms,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // 4. Decide se cria novo ou atualiza existente
      if (widget.entry == null) {
        await _dbService.createEntry(entry);  // CRIAR
      } else {
        await _dbService.updateEntry(entry);  // ATUALIZAR
      }

      // 5. Volta para a tela anterior com sucesso
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Exibe uma mensagem de erro na parte inferior da tela
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina o título da tela com base na operação
    final titulo = widget.entry == null ? 'Novo ciclo' : 'Editar ciclo';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── SEÇÃO: Datas ──────────────────────────────
            _SectionTitle(title: 'Datas'),

            // Seletor: Data de início
            _DateSelector(
              label: 'Data de início *',
              date: _startDate,
              onTap: () async {
                final data = await _escolherData(
                  initial: _startDate ?? DateTime.now(),
                  first: DateTime(2000),
                  last: DateTime.now(),
                );
                if (data != null) setState(() => _startDate = data);
              },
            ),
            const SizedBox(height: 12),

            // Seletor: Data de término
            _DateSelector(
              label: 'Data de término (opcional)',
              date: _endDate,
              onTap: () async {
                final data = await _escolherData(
                  initial: _endDate ?? (_startDate ?? DateTime.now()),
                  first: _startDate ?? DateTime(2000),
                  last: DateTime.now(),
                );
                if (data != null) setState(() => _endDate = data);
              },
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: Duração ────────────────────────────
            _SectionTitle(title: 'Duração'),

             // Slider: Duração do ciclo
            _SliderField(
              label: 'Duração do ciclo',
              value: _cycleLength.toDouble(),
              min: 20,
              max: 45,
              unit: 'dias',
              onChanged: (v) => setState(() => _cycleLength = v.round()),
            ),
            const SizedBox(height: 12),

            // Slider: Duração do período
            _SliderField(
              label: 'Duração do período',
              value: _periodLength.toDouble(),
              min: 1,
              max: 10,
              unit: 'dias',
              onChanged: (v) => setState(() => _periodLength = v.round()),
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: Humor ──────────────────────────────
            _SectionTitle(title: 'Como você está se sentindo?'),

            // Grade de botões de humor
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.map((mood) {
                final selecionado = _mood == mood;
                return FilterChip(
                  label: Text('${_moodEmojis[mood]} $mood'),
                  selected: selecionado,
                  // Ao tocar: seleciona ou deseleciona o humor
                  onSelected: (_) =>
                      setState(() => _mood = selecionado ? null : mood),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: Sintomas ───────────────────────────
            _SectionTitle(title: 'Sintomas'),

            // Lista de checkboxes de sintomas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomOptions.map((sintoma) {
                final marcado = _symptoms.contains(sintoma);
                return FilterChip(
                  label: Text(sintoma),
                  selected: marcado,
                  // Ao tocar: adiciona ou remove o sintoma da lista
                  onSelected: (_) {
                    setState(() {
                      if (marcado) {
                        _symptoms.remove(sintoma);
                      } else {
                        _symptoms.add(sintoma);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── SEÇÃO: Anotações ──────────────────────────
            _SectionTitle(title: 'Anotações'),

            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escreva qualquer observação sobre este ciclo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── BOTÃO SALVAR ──────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _salvar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Salvar',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS AUXILIARES DA TELA
// São componentes visuais simples criados aqui mesmo
// para evitar repetição de código
// ============================================================

// Título de seção com linha abaixo
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

// Botão que mostra uma data selecionada (ou "Selecionar")
class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  date != null ? fmt.format(date!) : 'Toque para selecionar',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Slider com label e valor atual exibidos
class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '${value.round()} $unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(), // um "passo" por dia
          onChanged: onChanged,
        ),
      ],
    );
  }
}
