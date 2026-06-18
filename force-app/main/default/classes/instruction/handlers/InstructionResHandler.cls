public with sharing class InstructionResHandler {
  public static InstructionDataModel.InstructionData handleResponse(
    Map<String, Object> response
  ) {
    InstructionValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    InstructionResModel.ResponseJson parsed = (InstructionResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      InstructionResModel.ResponseJson.class
    );

    InstructionValidator.validateTypedBody(parsed);

    InstructionResModel.InstructionRecord record = parsed.customObjectRecords[0];

    InstructionDataModel.InstructionData result = new InstructionDataModel.InstructionData();

    result.internalId = record.internalId;
    
    result.nsEmployeeId = record.owner == null ? null : record.owner.internalId;

    if (
      record.customFieldList != null &&
      record.customFieldList.customField != null
    ) {
      for (
        InstructionResModel.CustomField field : record.customFieldList.customField
      ) {
        if (field == null || String.isBlank(field.scriptId)) {
          continue;
        }

        if (field.scriptId == 'custrecord1') {
          result.nsSoId = field.valueLookup == null
            ? field.value
            : field.valueLookup.internalId;
        }

        if (field.scriptId == 'custrecord_instruction_comment') {
          result.instruction = field.value;
        }
      }
    }

    return result;
  }

  private static String extractJson(Map<String, Object> response) {
    Object raw = response.get('responseJSON');
    if (raw == null) {
      raw = response.get('requestJSON');
    }

    return raw instanceof String ? (String) raw : JSON.serialize(raw);
  }
}
