public with sharing class CommentMapper {
  public static List<CommentDataModel.CommentData> deserializeComments(
    String commentJson
  ) {
    try {
      return (List<CommentDataModel.CommentData>) JSON.deserialize(
        commentJson,
        List<CommentDataModel.CommentData>.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid comment payload.'
      );

      e.setMessage('Invalid comment payload.');

      throw e;
    }
  }
}
