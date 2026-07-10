@isTest
private class CommentMapperTest {
  @isTest
  static void deserializeComments_success() {
    CommentDataModel.CommentData comment = new CommentDataModel.CommentData();
    comment.internalId = 'COMMENT-001';
    comment.nsEmployeeId = 'EMP-001';
    comment.nsEmployeeName = 'Comment Employee';
    comment.nsSoId = 'SO-001';
    comment.comment = 'Repair comment text';
    comment.lastModified = Datetime.newInstanceGmt(2026, 7, 10, 15, 30, 0);

    List<CommentDataModel.CommentData> result = CommentMapper.deserializeComments(
      JSON.serialize(new List<CommentDataModel.CommentData>{ comment })
    );

    System.assertEquals(1, result.size());
    System.assertEquals('COMMENT-001', result[0].internalId);
    System.assertEquals('EMP-001', result[0].nsEmployeeId);
    System.assertEquals('Comment Employee', result[0].nsEmployeeName);
    System.assertEquals('SO-001', result[0].nsSoId);
    System.assertEquals('Repair comment text', result[0].comment);
    System.assertEquals(comment.lastModified, result[0].lastModified);
  }

  @isTest
  static void deserializeComments_emptyList() {
    List<CommentDataModel.CommentData> result = CommentMapper.deserializeComments(
      JSON.serialize(new List<CommentDataModel.CommentData>())
    );

    System.assertEquals(0, result.size());
  }

  @isTest
  static void deserializeComments_invalidJson() {
    try {
      CommentMapper.deserializeComments('not a json');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Invalid comment payload'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
