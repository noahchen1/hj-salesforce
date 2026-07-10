public with sharing class InstructionPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String instruction
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
    Map<String, Object> instructionRequest,
    Boolean isUpdate
  ) {
    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'customObjectRecords' => new List<Object>{ instructionRequest },
      'customObjectID' => '109'
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
