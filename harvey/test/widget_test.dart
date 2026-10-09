import 'package:flutter_test/flutter_test.dart';
import 'package:harvey/core/settings/settings_service.dart';
import 'package:harvey/features/contracts/contract_service.dart';
import 'package:harvey/features/matters/models/clause.dart';
import 'package:harvey/features/matters/models/contract.dart';
import 'package:harvey/features/matters/models/matter.dart';
import 'package:harvey/features/qa/legal_qa_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Models & Clause Serialization Tests', () {
    test('Clause toMap and fromMap with passage citation', () {
      const clause = Clause(
        id: 'cl_1',
        contractId: 'c_1',
        clauseType: 'liability_cap',
        sectionNumber: '§ 12.1',
        sectionTitle: 'Limitation of Liability',
        summaryValue: '12 months fees paid',
        verbatimPassage: 'Liability shall not exceed fees paid in prior 12 months.',
        pageNumber: 10,
        citation: '[Acme MSA, § 12.1, p. 10]',
        createdAt: 100000,
      );

      final map = clause.toMap();
      final restored = Clause.fromMap(map);

      expect(restored.id, equals('cl_1'));
      expect(restored.clauseType, equals('liability_cap'));
      expect(restored.type, equals(ClauseType.liabilityCap));
      expect(restored.sectionNumber, equals('§ 12.1'));
      expect(restored.citation, equals('[Acme MSA, § 12.1, p. 10]'));
    });

    test('Contract and Matter toMap and fromMap', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final contract = Contract(
        id: 'c1',
        matterId: 'm1',
        title: 'Vendor Master Services Agreement',
        filePath: '/path/to/contract.pdf',
        pageCount: 12,
        rawText: 'Full contract text...',
        createdAt: now,
      );

      final cMap = contract.toMap();
      final restoredC = Contract.fromMap(cMap);
      expect(restoredC.title, equals('Vendor Master Services Agreement'));
      expect(restoredC.pageCount, equals(12));

      final matter = Matter(
        id: 'm1',
        name: 'Project Falcon',
        description: 'Due diligence',
        contracts: [restoredC],
        createdAt: now,
        updatedAt: now,
      );

      final mMap = matter.toMap();
      final restoredM = Matter.fromMap(mMap, contracts: matter.contracts);
      expect(restoredM.name, equals('Project Falcon'));
      expect(restoredM.contracts.length, equals(1));
    });
  });

  group('ContractService & Clause Extraction Tests', () {
    test('Extracts 6 standard legal clauses with exact citations', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = ContractService(settings);

      const contract = Contract(
        id: 'test_c',
        matterId: 'test_m',
        title: 'Acme MSA',
        filePath: 'mock.txt',
        pageCount: 15,
        rawText: 'Section 11.1 Governing Law. This Agreement is governed by Delaware law.',
        createdAt: 0,
      );

      final clauses = await service.extractClauses(contract);
      expect(clauses.length, equals(6));

      final types = clauses.map((c) => c.clauseType).toSet();
      expect(
        types,
        containsAll([
          'governing_law',
          'termination',
          'indemnity',
          'liability_cap',
          'confidentiality',
          'assignment',
        ]),
      );

      for (final cl in clauses) {
        expect(cl.citation, contains('[Acme MSA, §'));
        expect(cl.citation, contains('p.'));
      }
    });
  });

  group('LegalQaService Cross-Contract Tests', () {
    test('Synthesizes multi-contract answer with passage-level citations', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final qaService = LegalQaService(settings);

      final contracts = [
        const Contract(
          id: 'c1',
          matterId: 'm1',
          title: 'Acme MSA',
          filePath: 'c1.pdf',
          pageCount: 10,
          rawText: 'text',
          clauses: [
            Clause(
              id: 'cl1',
              contractId: 'c1',
              clauseType: 'liability_cap',
              sectionNumber: '§ 12.1',
              sectionTitle: 'Limitation of Liability',
              summaryValue: '12 months fees paid',
              verbatimPassage: 'Liability capped at 12 months fees.',
              pageNumber: 10,
              citation: '[Acme MSA, § 12.1, p. 10]',
              createdAt: 0,
            ),
          ],
          createdAt: 0,
        ),
        const Contract(
          id: 'c2',
          matterId: 'm1',
          title: 'NovaTech NDA',
          filePath: 'c2.pdf',
          pageCount: 5,
          rawText: 'text',
          clauses: [
            Clause(
              id: 'cl2',
              contractId: 'c2',
              clauseType: 'liability_cap',
              sectionNumber: '§ 8.3',
              sectionTitle: 'Damages',
              summaryValue: 'Uncapped for confidentiality breaches',
              verbatimPassage: 'Direct damages uncapped for willful disclosure.',
              pageNumber: 4,
              citation: '[NovaTech NDA, § 8.3, p. 4]',
              createdAt: 0,
            ),
          ],
          createdAt: 0,
        ),
      ];

      final result = await qaService.answerQuery(
        query: 'Compare liability caps across agreements',
        contracts: contracts,
      );

      expect(result.answer, contains('Liability Cap'));
      expect(result.citations, contains('[Acme MSA, § 12.1, p. 10]'));
      expect(result.citations, contains('[NovaTech NDA, § 8.3, p. 4]'));
    });
  });
}
