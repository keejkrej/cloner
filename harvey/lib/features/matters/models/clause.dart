enum ClauseType {
  governingLaw('governing_law', 'Governing Law'),
  termination('termination', 'Termination'),
  indemnity('indemnity', 'Indemnity'),
  liabilityCap('liability_cap', 'Liability Cap'),
  confidentiality('confidentiality', 'Confidentiality'),
  assignment('assignment', 'Assignment');

  final String code;
  final String label;
  const ClauseType(this.code, this.label);

  static ClauseType fromCode(String code) {
    return ClauseType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ClauseType.governingLaw,
    );
  }
}

class Clause {
  final String id;
  final String contractId;
  final String clauseType; // code from ClauseType
  final String sectionNumber; // e.g. "§ 14.2"
  final String sectionTitle;
  final String summaryValue; // e.g. "State of Delaware"
  final String verbatimPassage;
  final int pageNumber;
  final String citation; // e.g. "[Acme MSA, § 14.2, p. 7]"
  final int createdAt;

  const Clause({
    required this.id,
    required this.contractId,
    required this.clauseType,
    required this.sectionNumber,
    required this.sectionTitle,
    required this.summaryValue,
    required this.verbatimPassage,
    required this.pageNumber,
    required this.citation,
    required this.createdAt,
  });

  ClauseType get type => ClauseType.fromCode(clauseType);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'clause_type': clauseType,
      'section_number': sectionNumber,
      'section_title': sectionTitle,
      'summary_value': summaryValue,
      'verbatim_passage': verbatimPassage,
      'page_number': pageNumber,
      'citation': citation,
      'created_at': createdAt,
    };
  }

  factory Clause.fromMap(Map<String, dynamic> map) {
    return Clause(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      clauseType: map['clause_type'] as String,
      sectionNumber: map['section_number'] as String,
      sectionTitle: map['section_title'] as String,
      summaryValue: map['summary_value'] as String,
      verbatimPassage: map['verbatim_passage'] as String,
      pageNumber: map['page_number'] as int,
      citation: map['citation'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
