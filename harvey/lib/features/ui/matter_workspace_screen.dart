import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../contracts/contract_service.dart';
import '../matters/matter_repository.dart';
import '../matters/models/clause.dart';
import '../matters/models/matter.dart';
import '../qa/legal_qa_service.dart';
import '../qa/models/qa_message.dart';

class MatterWorkspaceScreen extends StatefulWidget {
  final Matter initialMatter;
  final MatterRepository repository;
  final ContractService contractService;
  final LegalQaService qaService;

  const MatterWorkspaceScreen({
    super.key,
    required this.initialMatter,
    required this.repository,
    required this.contractService,
    required this.qaService,
  });

  @override
  State<MatterWorkspaceScreen> createState() => _MatterWorkspaceScreenState();
}

class _MatterWorkspaceScreenState extends State<MatterWorkspaceScreen> with SingleTickerProviderStateMixin {
  late Matter _matter;
  late final TabController _tabController;
  final _qaInputController = TextEditingController();
  final _qaScrollController = ScrollController();
  final _uuid = const Uuid();

  List<QaMessage> _qaMessages = [];
  bool _isAsking = false;
  bool _isIngesting = false;

  final _clauseTypes = [
    ClauseType.governingLaw,
    ClauseType.termination,
    ClauseType.liabilityCap,
    ClauseType.indemnity,
    ClauseType.confidentiality,
    ClauseType.assignment,
  ];

  @override
  void initState() {
    super.initState();
    _matter = widget.initialMatter;
    _tabController = TabController(length: 3, vsync: this);
    _loadQaMessages();
  }

  Future<void> _loadQaMessages() async {
    final msgs = await widget.repository.getQaMessages(_matter.id);
    setState(() => _qaMessages = msgs);
  }

  Future<void> _refreshMatter() async {
    final updated = await widget.repository.getMatter(_matter.id);
    if (updated != null && mounted) {
      setState(() => _matter = updated);
    }
  }

  Future<void> _uploadContract() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final path = result.first.path!;
      final title = result.first.name.replaceAll(RegExp(r'\.[^.]+$'), '');

      setState(() => _isIngesting = true);

      try {
        final contract = await widget.contractService.ingestContract(
          matterId: _matter.id,
          filePath: path,
          title: title,
        );

        await widget.repository.saveContract(contract);
        await widget.repository.saveClauses(contract.id, contract.clauses);
        await _refreshMatter();

        if (mounted) {
          setState(() => _isIngesting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ingested "${contract.title}" and extracted ${contract.clauses.length} clauses!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isIngesting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ingestion error: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendQaQuery([String? predefinedQuery]) async {
    final query = predefinedQuery ?? _qaInputController.text.trim();
    if (query.isEmpty || _isAsking) return;

    if (predefinedQuery == null) {
      _qaInputController.clear();
    }

    final userMsg = QaMessage(
      id: _uuid.v4(),
      matterId: _matter.id,
      role: 'user',
      content: query,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.repository.saveQaMessage(userMsg);
    setState(() {
      _qaMessages.add(userMsg);
      _isAsking = true;
    });
    _scrollToBottom();

    try {
      final result = await widget.qaService.answerQuery(
        query: query,
        contracts: _matter.contracts,
      );

      final assistantMsg = QaMessage(
        id: _uuid.v4(),
        matterId: _matter.id,
        role: 'assistant',
        content: result.answer,
        citations: result.citations,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveQaMessage(assistantMsg);

      if (mounted) {
        setState(() {
          _qaMessages.add(assistantMsg);
          _isAsking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAsking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Q&A error: $e')),
        );
      }
    }
  }

  void _showPassageModal(Clause clause, String contractTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.indigoAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${clause.sectionTitle} (${clause.sectionNumber})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  clause.citation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.indigoAccent,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Extracted Legal Term:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                clause.summaryValue,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Verbatim Contract Passage:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  clause.verbatimPassage,
                  style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_qaScrollController.hasClients) {
        _qaScrollController.animateTo(
          _qaScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qaInputController.dispose();
    _qaScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _matter.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${_matter.contracts.length} agreements indexed • Cross-contract due diligence',
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade700),
            onPressed: _isIngesting ? null : _uploadContract,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Contract (PDF)'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.indigoAccent,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart, size: 18), text: 'Clause Review Table'),
            Tab(icon: Icon(Icons.question_answer, size: 18), text: 'Legal Q&A with Citations'),
            Tab(icon: Icon(Icons.description, size: 18), text: 'Agreements & Sources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewTableTab(),
          _buildLegalQaTab(),
          _buildAgreementsTab(),
        ],
      ),
    );
  }

  // Tab 1: Clause Review Table (rows = contracts, columns = clause types)
  Widget _buildReviewTableTab() {
    if (_matter.contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_chart_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('No contracts in this matter yet.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _uploadContract,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload First Contract'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 14,
        horizontalMargin: 12,
        minWidth: 1200,
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1E2333)),
        border: TableBorder.all(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        columns: [
          const DataColumn2(
            label: Text('Contract Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            size: ColumnSize.L,
          ),
          ..._clauseTypes.map((type) {
            return DataColumn2(
              label: Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              size: ColumnSize.M,
            );
          }),
        ],
        rows: _matter.contracts.map((contract) {
          return DataRow2(
            cells: [
              // Contract title column
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      contract.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      '${contract.pageCount} pages',
                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              // Clause columns
              ..._clauseTypes.map((type) {
                final clause = contract.clauses.where((c) => c.clauseType == type.code).firstOrNull;

                if (clause == null) {
                  return const DataCell(
                    Text('—', style: TextStyle(color: Colors.white24)),
                  );
                }

                return DataCell(
                  InkWell(
                    onTap: () => _showPassageModal(clause, contract.title),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            clause.summaryValue,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            clause.citation,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.indigoAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Tab 2: Cross-Contract Legal Q&A
  Widget _buildLegalQaTab() {
    final sampleQuestions = [
      'Compare liability caps across all agreements',
      'Which contract has the shortest termination notice period?',
      'Identify governing law and jurisdictional conflicts',
      'What are the confidentiality obligations and post-termination survival terms?',
    ];

    return Column(
      children: [
        // Quick Question Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF161922),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Colors.indigoAccent),
              const SizedBox(width: 8),
              const Text('Suggested: ', style: TextStyle(fontSize: 11, color: Colors.white60)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sampleQuestions.map((q) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 11)),
                          onPressed: _isAsking ? null : () => _sendQaQuery(q),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Message Thread
        Expanded(
          child: _qaMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.balance, size: 48, color: Colors.indigoAccent),
                      const SizedBox(height: 14),
                      const Text(
                        'Ask questions across all indexed contracts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Every assertion will be cited back to exact passages: [Contract, §, p.]',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _qaScrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _qaMessages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final msg = _qaMessages[index];
                    final isUser = msg.role == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.indigo.shade700 : const Color(0xFF1B1F2D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isUser ? Colors.indigoAccent : Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: msg.content,
                              styleSheet: MarkdownStyleSheet(
                                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                                p: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white),
                                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            if (msg.citations.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Colors.white12),
                              const SizedBox(height: 8),
                              const Text('Passage-Level Citations:', style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: msg.citations.map((c) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigoAccent, fontFamily: 'monospace'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        if (_isAsking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.indigo.withValues(alpha: 0.15),
            child: const Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent)),
                SizedBox(width: 10),
                Text('Retrieving contract passages and synthesizing legal citations...', style: TextStyle(fontSize: 12, color: Colors.indigoAccent)),
              ],
            ),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qaInputController,
                  decoration: const InputDecoration(
                    hintText: 'Ask a question across all contracts in this matter...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendQaQuery(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.indigo.shade700),
                onPressed: _isAsking ? null : () => _sendQaQuery(),
                icon: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tab 3: Agreements & Sources
  Widget _buildAgreementsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _matter.contracts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _matter.contracts[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.indigoAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.pageCount} pages • ${c.clauses.length} structured clauses extracted and cited',
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('View in Table', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
