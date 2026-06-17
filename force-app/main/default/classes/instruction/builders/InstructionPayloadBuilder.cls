public with sharing class InstructionPayloadBuilder {
  public static Map<String, Object> buildCreateRequest(
    String nsEmployeeId,
    String nsSoId,
    String instruction
  ) {
    List<Object> customObjectCustomFieldList = new List<Object>();

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'select',
        'scriptId' => 'owner',
        'value' => nsEmployeeId
      }
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

    return new Map<String, Object>{
      'customFieldList' => new Map<String, Object>{
        'customField' => customObjectCustomFieldList
      }
    };
  }

  public static Map<String, Object> buildCreatePayload(
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
}
