public with sharing class NsNoteController {
  @AuraEnabled(cacheable=false)
  public static String saveNote(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String content
  ) {
    return NsNoteService.saveNote(nsInternalId, nsEmployeeId, nsSoId, content);
  }

  @AuraEnabled(cacheable=false)
  public static List<NsNoteDataModel.NsNoteData> getNoteData(Id salesOrderId) {
    return NsNoteService.getNoteData(salesOrderId);
  }
}
