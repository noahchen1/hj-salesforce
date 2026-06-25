public with sharing class NsNoteController {
  @AuraEnabled(cacheable=false)
  public static String saveNote(
    String nsEmployeeId,
    String nsSoId,
    String content
  ) {
    return NsNoteService.saveNote(nsEmployeeId, nsSoId, content);
  }
}
