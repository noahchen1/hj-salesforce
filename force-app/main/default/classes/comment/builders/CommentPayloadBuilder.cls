public with sharing class CommentPayloadBuilder {
  public static Map<String, Object> buildCreateRequest(
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();
    List<Object> customObjectCustomFieldList = new List<Object>();

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
    Map<String, Object> commentRequest
  ) {
    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'customObjectRecords' => new List<Object>{ commentRequest },
      'customObjectID' => '110'
    };

    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'createCustomObjectRecord',
      'requestJSON' => JSON.serialize(requestJsonMap)
    };
  }

  public static Map<String, Object> buildReadRequest(String nsSoId) {
    Map<String, Object> filters = new Map<String, Object>{
      'custrecord_parent_record' => nsSoId
    };

    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };

    return new Map<String, Object>{
      'customObjectID' => '110',
      'customParameters' => filterMap
    };
  }

  public static Map<String, Object> buildReadPayload(Map<String, Object> request) {
    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'readCustomObjectRecord',
      'requestJSON' => JSON.serialize(request)
    };
  }
}
