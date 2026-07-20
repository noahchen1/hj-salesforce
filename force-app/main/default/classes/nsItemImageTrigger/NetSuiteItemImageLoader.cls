public with sharing class NetSuiteItemImageLoader {
  private static NetSuiteItemImageLoader instance;
  private static final Logger LOGGER = new Logger(
    NetSuiteItemImageLoader.class.getName()
  );

  private NetSuiteItemImageLoader() {
  }

  public static NetSuiteItemImageLoader getInstance() {
    if (instance == null) {
      instance = new NetSuiteItemImageLoader();
    }
    return instance;
  }

  public void loadImage(Set<Id> netSuiteItemIds) {
    try {
      Set<String> previousImageIds = new Set<String>();
      List<ContentVersion> contentVersions = new List<ContentVersion>();
      Map<String, Id> contentVersionTitleToItemId = new Map<String, Id>();

      for (
        breadwinner_ns__BW_Item__c item : getNetSuiteItems(netSuiteItemIds)
      ) {
        try {
          ContentVersion contentVersion = createContentVersion(item);
          contentVersions.add(contentVersion);
          contentVersionTitleToItemId.put(contentVersion.Title, item.Id);
          previousImageIds.add(item.imageId__c);
        } catch (Exception ex) {
          LOGGER.logError(ex, item.Id);
        }
      }

      removePreviousImages(previousImageIds);
      insert contentVersions;
      buildContentDocumentLinksAndUpdateItems(
        fetchInsertedContentVersions(contentVersions),
        contentVersionTitleToItemId
      );
    } catch (Exception ex) {
      LOGGER.logError(ex);
    } finally {
      LOGGER.publishLogs();
    }
  }

  private List<breadwinner_ns__BW_Item__c> getNetSuiteItems(
    Set<Id> netSuiteItemIds
  ) {
    return [
      SELECT
        Name,
        imageId__c,
        ncf_item_web_image1_link__c,
        ncf_item_show_image_link__c
      FROM breadwinner_ns__BW_Item__c
      WHERE Id IN :netSuiteItemIds
    ];
  }

  private ContentVersion createContentVersion(breadwinner_ns__BW_Item__c item) {
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = getImageName(item);
    contentVersion.PathOnClient = contentVersion.Title + '.jpg';
    contentVersion.VersionData = downloadImage(item);
    contentVersion.IsMajorVersion = true;
    return contentVersion;
  }

  private void removePreviousImages(Set<String> previousImageIds) {
    delete [SELECT Id FROM ContentDocument WHERE Id IN :previousImageIds];
  }

  private List<ContentVersion> fetchInsertedContentVersions(
    List<ContentVersion> contentVersions
  ) {
    return [
      SELECT Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id IN :contentVersions
    ];
  }

  private void buildContentDocumentLinksAndUpdateItems(
    List<ContentVersion> contentVersions,
    Map<String, Id> contentVersionTitleToItemId
  ) {
    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    List<breadwinner_ns__BW_Item__c> itemsToUpdate = new List<breadwinner_ns__BW_Item__c>();

    for (ContentVersion contentVersion : contentVersions) {
      Id itemId = contentVersionTitleToItemId.get(contentVersion.Title);
      links.add(
        new ContentDocumentLink(
          ContentDocumentId = contentVersion.ContentDocumentId,
          LinkedEntityId = itemId,
          Visibility = 'AllUsers',
          ShareType = 'I'
        )
      );
      itemsToUpdate.add(
        new breadwinner_ns__BW_Item__c(
          Id = itemId,
          imageId__c = contentVersion.ContentDocumentId
        )
      );
    }
    insert links;
    update itemsToUpdate;
  }

  private Blob downloadImage(breadwinner_ns__BW_Item__c netSuiteItem) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(getEndpoint(netSuiteItem));
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);

    if (res.getStatusCode() == 302) {
      String newUrl = res.getHeader('Location');
      if (newUrl != null) {
        req = new HttpRequest();
        req.setEndpoint(newUrl);
        req.setMethod('GET');
        res = http.send(req);
      }
    } else if (res.getStatusCode() != 200) {
      throw new NetSuiteItemImageLoaderException(
        'Endpoint: ' +
          req.getEndpoint() +
          '\n' +
          'Status: ' +
          res.getStatus() +
          '\n' +
          'Status Code : ' +
          res.getStatusCode()
      );
    }

    return res.getBodyAsBlob();
  }

  private String getEndpoint(breadwinner_ns__BW_Item__c item) {
    return String.isNotBlank(item.ncf_item_web_image1_link__c)
      ? item.ncf_item_web_image1_link__c
      : item.ncf_item_show_image_link__c;
  }

  private String getImageName(breadwinner_ns__BW_Item__c netSuiteItem) {
    return netSuiteItem.Name + '_' + System.currentTimeMillis();
  }

  class NetSuiteItemImageLoaderException extends Exception {
  }
}
