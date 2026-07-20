public with sharing class EnhancedMessagingService {
  private static final String API_VERSION = 'v67.0';

  public static void sendMessage(List<Id> messagingEndUserIds) {
    if (messagingEndUserIds == null || messagingEndUserIds.isEmpty()) {
      throw new EnhancedMessagingException(
        'At least one MessagingEndUser ID is required.'
      );
    }

    List<String> recipientIds = new List<String>();

    for (Id messagingEndUserId : messagingEndUserIds) {
      if (messagingEndUserId != null) {
        recipientIds.add(String.valueOf(messagingEndUserId));
      }
    }

    if (recipientIds.isEmpty()) {
      throw new EnhancedMessagingException(
        'At least one non-null MessagingEndUser ID is required.'
      );
    }

    String sessionId = UserInfo.getSessionId();

    if (String.isBlank(sessionId)) {
      throw new EnhancedMessagingException(
        'No Salesforce session ID is available in this execution context.'
      );
    }

    Map<String, Object> actionInput = new Map<String, Object>{
      'messageDefinitionName' => 'Item_SMS',
      'requestType' => 'SendNotificationMessages',
      'isEnforceMessagingChannelConsent' => true,
      'channelConsentType' => 'MessagingEndUser',
      'allowedSessionStatus' => 'Any',
      // The REST action expects a comma-separated string.
      'messagingEndUserIds' => messagingEndUserIds
    };

    /*
        actionInput.put(
            'messagingDefinitionInputParameters',
            new List<Object>{
                new Map<String, Object>{
                    'name' => 'Product_Name',
                    'textValue' => 'Test Product'
                },
                new Map<String, Object>{
                    'name' => 'Image_Url',
                    'textValue' => 'https://public.example.com/image.jpg'
                }
            }
        );
        */

    Map<String, Object> payload = new Map<String, Object>{
      'inputs' => new List<Object>{ actionInput }
    };

    String endpoint =
      URL.getOrgDomainUrl().toExternalForm() +
      '/services/data/' +
      API_VERSION +
      '/actions/standard/sendConversationMessages';

    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + sessionId);
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Accept', 'application/json');
    request.setTimeout(120000);
    request.setBody(JSON.serialize(payload));

    System.debug('Endpoint: ' + endpoint);
    System.debug('Request body: ' + request.getBody());

    HttpResponse response;

    try {
      response = new Http().send(request);
    } catch (CalloutException ex) {
      throw new EnhancedMessagingException(
        'REST callout failed: ' + ex.getMessage()
      );
    }

    System.debug('Status code: ' + response.getStatusCode());
    System.debug('Response body: ' + response.getBody());

    if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
      throw new EnhancedMessagingException(
        'Send Conversation Messages failed. HTTP ' +
          response.getStatusCode() +
          ' ' +
          response.getStatus() +
          '. Response: ' +
          response.getBody()
      );
    }

    validateActionResponse(response.getBody());
  }

  private static void validateActionResponse(String responseBody) {
    if (String.isBlank(responseBody)) {
      return;
    }

    Object rawResponse = JSON.deserializeUntyped(responseBody);

    if (!(rawResponse instanceof List<Object>)) {
      throw new EnhancedMessagingException(
        'Unexpected response format: ' + responseBody
      );
    }

    List<Object> results = (List<Object>) rawResponse;

    if (results.isEmpty()) {
      throw new EnhancedMessagingException(
        'The REST action returned no results.'
      );
    }

    Map<String, Object> firstResult = (Map<String, Object>) results[0];

    Boolean success = (Boolean) firstResult.get('isSuccess');

    if (success != true) {
      throw new EnhancedMessagingException(
        'Send Conversation Messages returned an error: ' + responseBody
      );
    }

    System.debug(
      'Send Conversation Messages succeeded: ' +
      JSON.serializePretty(firstResult)
    );
  }

  public class EnhancedMessagingException extends Exception {
  }
}
