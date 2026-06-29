public with sharing class NsNotePayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String content
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();
    List<Object> customObjectCustomFieldList = new List<Object>();

    if (String.isNotBlank(nsInternalId)) {
      requestMap.put('internalId', nsInternalId);
    }

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_note_history_author',
        'value' => nsEmployeeId
      }
    );

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_note_history_transaction',
        'value' => nsSoId
      }
    );

    customObjectCustomFieldList.add(
      new Map<String, Object>{
        'fieldType' => 'string',
        'scriptId' => 'custrecord_note_history_content',
        'value' => content
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
      'customObjectID' => '3131' //check production!!!!
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
