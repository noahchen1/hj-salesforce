public with sharing class CommentController {
    @AuraEnabled
    public static String saveComment(
        String nsEmployeeId,
        String nsSoId,
        String comment
    ) {
        return CommentService.saveComment(nsEmployeeId, nsSoId, comment);
    }

    @AuraEnabled(cacheable=false)
    public static List<CommentDataModel.CommentData> getCommentData(
        Id salesOrderId
    ) {
        return CommentService.getCommentData(salesOrderId);
    }
}