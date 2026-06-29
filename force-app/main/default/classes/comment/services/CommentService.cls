public with sharing class CommentService {
  public static String saveComment(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    CommentValidator.validateSaveRequest(nsEmployeeId, nsSoId, comment);
    Boolean isUpdate = String.isNotBlank(nsInternalId);

    Map<String, Object> commentRequest = CommentPayloadBuilder.buildCreateRequest(
      nsInternalId,
      nsEmployeeId,
      nsSoId,
      comment
    );

    Map<String, Object> requestPayload = CommentPayloadBuilder.buildCreatePayload(
      commentRequest,
      isUpdate
    );

    System.debug(
      LoggingLevel.INFO,
      'CommentService.saveComment request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'CommentService.saveComment response: ' + JSON.serialize(response)
    );

    CommentDataModel.CommentData commentData = CommentResHandler.handleResponse(
      response
    );

    return commentData.internalId;
  }

  public static List<CommentDataModel.CommentData> getCommentData(
    Id salesOrderId
  ) {
    if (salesOrderId == null) {
      throw new AuraHandledException('Sales order Id is required.');
    }

    List<nco_repair_comments__c> commentRows = [
      SELECT
        InternalId__c,
        OwnerName__c,
        nid_record_parent_record__c,
        custrecord_repair_comments__c,
        LastModified__c
      FROM nco_repair_comments__c
      WHERE ncl_record_parent_record__c = :salesOrderId
    ];

    if (commentRows.isEmpty()) {
      throw new AuraHandledException('Could not find related comments');
    }

    Set<String> ownerNames = new Set<String>();

    for (nco_repair_comments__c row : commentRows) {
      if (String.isNotBlank(row.OwnerName__c)) {
        ownerNames.add(row.OwnerName__c);
      }
    }

    Map<String, breadwinner_ns__BW_Employee__c> employeesByName = new Map<String, breadwinner_ns__BW_Employee__c>();

    for (breadwinner_ns__BW_Employee__c employee : [
      SELECT breadwinner_ns__InternalId__c, Name
      FROM breadwinner_ns__BW_Employee__c
      WHERE Name = :ownerNames
    ]) {
      employeesByName.put(employee.Name, employee);
    }

    List<CommentDataModel.CommentData> commentData = new List<CommentDataModel.CommentData>();

    for (nco_repair_comments__c row : commentRows) {
      breadwinner_ns__BW_Employee__c employee = employeesByName.get(
        row.OwnerName__c
      );

      if (employee == null) {
        throw new AuraHandledException(
          'Could not find NetSuite employee: ' + row.OwnerName__c
        );
      }

      CommentDataModel.CommentData data = new CommentDataModel.CommentData();

      data.internalId = row.InternalId__c;
      data.nsEmployeeId = employee.breadwinner_ns__InternalId__c;
      data.nsEmployeeName = employee.Name;
      data.nsSoId = row.nid_record_parent_record__c;
      data.comment = row.custrecord_repair_comments__c;
      data.lastModified = row.LastModified__c;

      commentData.add(data);
    }

    return commentData;
  }
}
