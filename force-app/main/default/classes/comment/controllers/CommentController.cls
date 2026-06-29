public with sharing class CommentController {
  @AuraEnabled
  public static String saveComment(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    return CommentService.saveComment(
      nsInternalId,
      nsEmployeeId,
      nsSoId,
      comment
    );
  }

  @AuraEnabled(cacheable=false)
  public static List<CommentDataModel.CommentData> getCommentData(
    Id salesOrderId
  ) {
    return CommentService.getCommentData(salesOrderId);
  }
}
