import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../qa/models/qa_message.dart';
import 'models/clause.dart';
import 'models/contract.dart';
import 'models/matter.dart';

class MatterRepository {
  final _uuid = const Uuid();

  Future<List<Matter>> getAllMatters() async {
    final db = await DatabaseService.database;
    final matterRows = await db.query('matters', orderBy: 'updated_at DESC');

    if (matterRows.isEmpty) {
      await _seedInitialMatter();
      return await getAllMatters();
    }

    final matters = <Matter>[];
    for (final mRow in matterRows) {
      final matterId = mRow['id'] as String;
      final contracts = await getContractsForMatter(matterId);
      matters.add(Matter.fromMap(mRow, contracts: contracts));
    }
    return matters;
  }

  Future<List<Contract>> getContractsForMatter(String matterId) async {
    final db = await DatabaseService.database;
    final cRows = await db.query('contracts', where: 'matter_id = ?', whereArgs: [matterId]);

    final contracts = <Contract>[];
    for (final cRow in cRows) {
      final contractId = cRow['id'] as String;
      final clauseRows = await db.query('clauses', where: 'contract_id = ?', whereArgs: [contractId]);
      final clauses = clauseRows.map((cl) => Clause.fromMap(cl)).toList();
      contracts.add(Contract.fromMap(cRow, clauses: clauses));
    }
    return contracts;
  }

  Future<Matter?> getMatter(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('matters', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final contracts = await getContractsForMatter(id);
    return Matter.fromMap(rows.first, contracts: contracts);
  }

  Future<void> saveMatter(Matter matter) async {
    final db = await DatabaseService.database;
    await db.insert('matters', matter.toMap(), conflictAlgorithm: null);
  }

  Future<void> saveContract(Contract contract) async {
    final db = await DatabaseService.database;
    await db.insert('contracts', contract.toMap(), conflictAlgorithm: null);
  }

  Future<void> saveClauses(String contractId, List<Clause> clauses) async {
    final db = await DatabaseService.database;
    await db.transaction((txn) async {
      await txn.delete('clauses', where: 'contract_id = ?', whereArgs: [contractId]);
      for (final cl in clauses) {
        await txn.insert('clauses', cl.toMap());
      }
    });
  }

  Future<void> deleteMatter(String id) async {
    final db = await DatabaseService.database;
    final contracts = await getContractsForMatter(id);
    for (final c in contracts) {
      await db.delete('clauses', where: 'contract_id = ?', whereArgs: [c.id]);
    }
    await db.delete('contracts', where: 'matter_id = ?', whereArgs: [id]);
    await db.delete('qa_messages', where: 'matter_id = ?', whereArgs: [id]);
    await db.delete('matters', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QaMessage>> getQaMessages(String matterId) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'qa_messages',
      where: 'matter_id = ?',
      whereArgs: [matterId],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => QaMessage.fromMap(r)).toList();
  }

  Future<void> saveQaMessage(QaMessage message) async {
    final db = await DatabaseService.database;
    await db.insert('qa_messages', message.toMap());
  }

  Future<void> _seedInitialMatter() async {
    final db = await DatabaseService.database;
    final matterId = 'matter_merger_due_diligence';
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('matters', {
      'id': matterId,
      'name': 'Project Falcon (Acquisition Due Diligence)',
      'description': 'Cross-contract review and risk assessment across strategic vendor agreements',
      'created_at': now,
      'updated_at': now,
    });

    // 1. Acme Corp Master Services Agreement
    final c1Id = 'contract_acme_msa';
    await db.insert('contracts', {
      'id': c1Id,
      'matter_id': matterId,
      'title': 'Acme Corp Master Services Agreement',
      'file_path': 'acme_msa.pdf',
      'page_count': 14,
      'raw_text': 'Master Services Agreement entered into by Acme Corp...',
      'created_at': now,
    });

    final c1Clauses = [
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'governing_law',
        sectionNumber: '§ 14.1',
        sectionTitle: 'Governing Law and Jurisdiction',
        summaryValue: 'Delaware law; exclusive state/federal courts in Wilmington',
        verbatimPassage: 'This Agreement shall be governed by and construed in accordance with the laws of the State of Delaware, without regard to its conflict of law principles. The parties submit to the exclusive jurisdiction of the state and federal courts in Wilmington, Delaware.',
        pageNumber: 12,
        citation: '[Acme MSA, § 14.1, p. 12]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'termination',
        sectionNumber: '§ 8.2',
        sectionTitle: 'Termination for Convenience and Cause',
        summaryValue: '30 days written notice for convenience; 15 days cure period for breach',
        verbatimPassage: 'Either party may terminate this Agreement without cause upon thirty (30) days prior written notice. Either party may terminate immediately if the other party breaches any material term and fails to cure such breach within fifteen (15) days.',
        pageNumber: 8,
        citation: '[Acme MSA, § 8.2, p. 8]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'indemnity',
        sectionNumber: '§ 11.3',
        sectionTitle: 'Mutual Indemnification',
        summaryValue: 'Mutual IP infringement indemnification & gross negligence defense',
        verbatimPassage: 'Vendor shall indemnify, defend, and hold harmless Customer from and against any third-party claims alleging that the Deliverables infringe any patent, copyright, or trademark, or arising from gross negligence or willful misconduct.',
        pageNumber: 9,
        citation: '[Acme MSA, § 11.3, p. 9]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'liability_cap',
        sectionNumber: '§ 12.1',
        sectionTitle: 'Limitation of Liability',
        summaryValue: '12 months fees paid under applicable Order Form',
        verbatimPassage: 'In no event shall either party\'s aggregate cumulative liability arising out of or related to this Agreement exceed the total amounts actually paid or payable by Customer in the twelve (12) months preceding the incident giving rise to liability.',
        pageNumber: 10,
        citation: '[Acme MSA, § 12.1, p. 10]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'confidentiality',
        sectionNumber: '§ 7.4',
        sectionTitle: 'Non-Disclosure and Confidentiality',
        summaryValue: '5 years post-termination; trade secrets perpetual',
        verbatimPassage: 'Each party agrees to safeguard Confidential Information with reasonable care for a period of five (5) years following termination, provided that trade secrets shall remain confidential perpetually.',
        pageNumber: 6,
        citation: '[Acme MSA, § 7.4, p. 6]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c1Id,
        clauseType: 'assignment',
        sectionNumber: '§ 14.5',
        sectionTitle: 'Assignment and Change of Control',
        summaryValue: 'No assignment without consent; permitted upon M&A with notice',
        verbatimPassage: 'Neither party may assign or transfer this Agreement without prior written consent, except to an affiliate or in connection with a merger, acquisition, or sale of substantially all assets upon prompt written notice.',
        pageNumber: 13,
        citation: '[Acme MSA, § 14.5, p. 13]',
        createdAt: now,
      ),
    ];
    for (final cl in c1Clauses) {
      await db.insert('clauses', cl.toMap());
    }

    // 2. NovaTech Mutual Non-Disclosure Agreement
    final c2Id = 'contract_novatech_nda';
    await db.insert('contracts', {
      'id': c2Id,
      'matter_id': matterId,
      'title': 'NovaTech Mutual NDA',
      'file_path': 'novatech_nda.pdf',
      'page_count': 5,
      'raw_text': 'Mutual Non-Disclosure Agreement between NovaTech and Partner...',
      'created_at': now,
    });

    final c2Clauses = [
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'governing_law',
        sectionNumber: '§ 9',
        sectionTitle: 'Governing Law',
        summaryValue: 'State of New York; courts located in New York County',
        verbatimPassage: 'This NDA shall be governed exclusively by the laws of the State of New York. The parties consent to personal jurisdiction in the courts located in New York County.',
        pageNumber: 4,
        citation: '[NovaTech NDA, § 9, p. 4]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'termination',
        sectionNumber: '§ 6',
        sectionTitle: 'Term and Expiration',
        summaryValue: '2-year term; terminable upon 10 days written notice',
        verbatimPassage: 'This NDA shall remain in effect for two (2) years from the Effective Date, and may be terminated by either party upon ten (10) days advance written notice.',
        pageNumber: 3,
        citation: '[NovaTech NDA, § 6, p. 3]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'indemnity',
        sectionNumber: '§ 8.1',
        sectionTitle: 'Injunctive Relief and Damages',
        summaryValue: 'No indemnification clause; equitable injunctive relief provided',
        verbatimPassage: 'Unauthorized disclosure causes irreparable harm for which damages are inadequate; the disclosing party is entitled to seek injunctive relief without bond.',
        pageNumber: 3,
        citation: '[NovaTech NDA, § 8.1, p. 3]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'liability_cap',
        sectionNumber: '§ 8.3',
        sectionTitle: 'Limitation on Consequential Damages',
        summaryValue: 'Uncapped for confidentiality breaches; excludes lost profits',
        verbatimPassage: 'Neither party shall be liable for indirect or punitive damages, provided that direct damages for willful breach of confidentiality shall not be subject to a monetary ceiling.',
        pageNumber: 4,
        citation: '[NovaTech NDA, § 8.3, p. 4]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'confidentiality',
        sectionNumber: '§ 3.2',
        sectionTitle: 'Duty of Confidentiality',
        summaryValue: '3 years from disclosure; standard exceptions for public info',
        verbatimPassage: 'Receiving Party shall preserve confidentiality for three (3) years from the date of disclosure using degree of care customary in the technology industry.',
        pageNumber: 2,
        citation: '[NovaTech NDA, § 3.2, p. 2]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c2Id,
        clauseType: 'assignment',
        sectionNumber: '§ 10',
        sectionTitle: 'Non-Assignability',
        summaryValue: 'Strictly non-assignable without consent',
        verbatimPassage: 'This NDA is personal to the parties and may not be assigned or delegated without the express prior written consent of the other party.',
        pageNumber: 4,
        citation: '[NovaTech NDA, § 10, p. 4]',
        createdAt: now,
      ),
    ];
    for (final cl in c2Clauses) {
      await db.insert('clauses', cl.toMap());
    }

    // 3. CloudScale Enterprise SaaS Agreement
    final c3Id = 'contract_cloudscale_saas';
    await db.insert('contracts', {
      'id': c3Id,
      'matter_id': matterId,
      'title': 'CloudScale Enterprise SaaS Agreement',
      'file_path': 'cloudscale_saas.pdf',
      'page_count': 18,
      'raw_text': 'Enterprise Cloud Services Subscription Agreement...',
      'created_at': now,
    });

    final c3Clauses = [
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'governing_law',
        sectionNumber: '§ 16.4',
        sectionTitle: 'Governing Law and Venue',
        summaryValue: 'State of California; courts of San Francisco County',
        verbatimPassage: 'This Subscription Agreement is governed by the laws of the State of California. Any suit, action or proceeding shall be brought in San Francisco, California.',
        pageNumber: 16,
        citation: '[CloudScale SaaS, § 16.4, p. 16]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'termination',
        sectionNumber: '§ 11.2',
        sectionTitle: 'Termination and Suspension',
        summaryValue: '60 days notice prior to renewal; 30 days cure for cause',
        verbatimPassage: 'Either party may elect non-renewal by providing written notice at least sixty (60) days prior to the end of the Current Term. Cause termination requires thirty (30) days cure.',
        pageNumber: 11,
        citation: '[CloudScale SaaS, § 11.2, p. 11]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'indemnity',
        sectionNumber: '§ 13.1',
        sectionTitle: 'Provider Infringement Indemnity',
        summaryValue: 'Provider defends against IP claims; excludes customer data misuse',
        verbatimPassage: 'CloudScale shall defend Customer against third-party claims alleging that the Cloud Service infringes any valid copyright or patent, paying damages awarded by final judgment.',
        pageNumber: 13,
        citation: '[CloudScale SaaS, § 13.1, p. 13]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'liability_cap',
        sectionNumber: '§ 14.2',
        sectionTitle: 'Super-Cap for Data Protection',
        summaryValue: 'General cap: 12 months fees; Data breach super-cap: 2x 12 months fees',
        verbatimPassage: 'Except for gross negligence or willful breach of data protection addendum (which shall be subject to a super-cap of two times (2x) the 12-month fees), liability is capped at fees paid in prior 12 months.',
        pageNumber: 14,
        citation: '[CloudScale SaaS, § 14.2, p. 14]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'confidentiality',
        sectionNumber: '§ 9.1',
        sectionTitle: 'Confidential Information and Security',
        summaryValue: 'Duration of Agreement plus 3 years; Security DPA incorporated',
        verbatimPassage: 'Confidentiality obligations survive for three (3) years post-expiration. CloudScale shall maintain SOC 2 Type II compliance for customer data.',
        pageNumber: 9,
        citation: '[CloudScale SaaS, § 9.1, p. 9]',
        createdAt: now,
      ),
      Clause(
        id: _uuid.v4(),
        contractId: c3Id,
        clauseType: 'assignment',
        sectionNumber: '§ 16.1',
        sectionTitle: 'Assignment',
        summaryValue: 'Consent required; permitted to successor entity in change of control',
        verbatimPassage: 'Customer may not assign without consent; CloudScale may assign without consent to a corporate successor pursuant to a merger or sale of assets.',
        pageNumber: 15,
        citation: '[CloudScale SaaS, § 16.1, p. 15]',
        createdAt: now,
      ),
    ];
    for (final cl in c3Clauses) {
      await db.insert('clauses', cl.toMap());
    }
  }
}
