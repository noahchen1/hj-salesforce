public with sharing class CommentPayloadBuilder {
  public static Map<String, Object> buildCreateRequest(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();
    List<Object> customObjectCustomFieldList = new List<Object>();

    if (String.isNotBlank(nsInternalId)) {
      requestMap.put('internalId', nsInternalId);
    }

    requestMap.put(
      'owner',
      new Map<String, Object>{ 'internalId' => nsEmployeeId }
    );

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_parent_record',
        'value' => nsSoId
      }
    );

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_repair_comments',
        'value' => comment
      }
    );

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => customObjectCustomFieldList }
    );

    return requestMap;
  }

  public static Map<String, Object> buildCreatePayload(
    Map<String, Object> commentRequest,
    Boolean isUpdate
  ) {
    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'customObjectRecords' => new List<Object>{ commentRequest },
      'customObjectID' => '110'
    };

    return isUpdate
      ? new Map<String, Object>{
          'version' => '1.0',
          'action' => 'updateCustomObjectRecord',
          'requestJSON' => JSON.serialize(requestJsonMap)
        }
      : new Map<String, Object>{
          'version' => '1.0',
          'action' => 'createCustomObjectRecord',
          'requestJSON' => JSON.serialize(requestJsonMap)
        };
  }
}
