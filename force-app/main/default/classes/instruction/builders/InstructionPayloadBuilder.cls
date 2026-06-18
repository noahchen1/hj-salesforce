public with sharing class InstructionPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String nsEmployeeId,
    String nsSoId,
    String instruction
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
        'scriptId' => 'custrecord1',
        'value' => nsSoId
      }
    );

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_instruction_comment',
        'value' => instruction
      }
    );

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => customObjectCustomFieldList }
    );

    return requestMap;
  }

  public static Map<String, Object> buildSavePayload(
    Map<String, Object> instructionRequest
  ) {
    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'customObjectRecords' => new List<Object>{ instructionRequest },
      'customObjectID' => '109'
    };

    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'createCustomObjectRecord',
      'requestJSON' => JSON.serialize(requestJsonMap)
    };
  }

  public static Map<String, Object> buildReadRequest(
    String nsSoId
  ) {
    Map<String, Object> filters = new Map<String, Object>{
      'custrecord1' => nsSoId
    };

    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };

    return new Map<String, Object>{
      'customObjectID' => '109',
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
