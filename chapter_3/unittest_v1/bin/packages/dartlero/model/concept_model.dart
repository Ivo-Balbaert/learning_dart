part of dartlero;

abstract class ConceptModelApi {

  Map<String, ConceptEntitiesApi> newEntries();
  ConceptEntitiesApi getEntry(String entryConcept);

}

abstract class ConceptModel implements ConceptModelApi {

  Map<String, ConceptEntities> _entryMap;

  ConceptModel() {
    _entryMap = newEntries();
  }

  ConceptEntities getEntry(String entryConcept) => _entryMap[entryConcept];

}
