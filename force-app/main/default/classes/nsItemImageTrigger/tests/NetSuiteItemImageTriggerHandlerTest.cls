@IsTest
public with sharing class NetSuiteItemImageTriggerHandlerTest {
  @IsTest
  static void loadImageOnAfterInsertTest() {
    String imageLink = 'https://5405357-sb1.app.netsuite.com/app/common/media/mediaitem.nl?id=1272560';
    breadwinner_ns__BW_Item__c netsuiteItem = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item',
      ncf_item_web_image1_link__c = imageLink,
      ncf_item_show_image_link__c = 'https://example.com/fallback-image.jpg'
    );

    Test.setMock(
      HttpCalloutMock.class,
      new NetSuiteItemImageRequestMock(imageLink)
    );

    Test.startTest();
    insert netsuiteItem;
    Test.getEventBus().deliver();
    Test.stopTest();

    System.assert(
      ![
          SELECT Id
          FROM ContentDocumentLink
          WHERE LinkedEntityId = :netsuiteItem.Id
        ]
        .isEmpty()
    );
    System.assert(
      [
        SELECT imageId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE Id = :netsuiteItem.Id
      ]
      .imageId__c != null
    );
  }

  @IsTest
  static void loadImageOnAfterUpdateTest() {
    String imageLink = 'https://5405357-sb1.app.netsuite.com/app/common/media/mediaitem.nl?id=1272560';
    breadwinner_ns__BW_Item__c netsuiteItem = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item'
    );
    insert netsuiteItem;

    Test.setMock(
      HttpCalloutMock.class,
      new NetSuiteItemImageRequestMock(imageLink)
    );

    Test.startTest();
    update new breadwinner_ns__BW_Item__c(
      Id = netsuiteItem.Id,
      ncf_item_show_image_link__c = imageLink
    );
    Test.getEventBus().deliver();
    Test.stopTest();

    System.assert(
      ![
          SELECT Id
          FROM ContentDocumentLink
          WHERE LinkedEntityId = :netsuiteItem.Id
        ]
        .isEmpty()
    );
    System.assert(
      [
        SELECT imageId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE Id = :netsuiteItem.Id
      ]
      .imageId__c != null
    );
  }

  @IsTest
  static void loadShowImageWhenExistingImageIdAndWebImageLinkIsBlankTest() {
    ContentVersion previousImage = new ContentVersion(
      Title = 'Previous Image',
      PathOnClient = 'previous-image.jpg',
      VersionData = Blob.valueOf('previous image')
    );
    insert previousImage;
    Id previousImageId = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :previousImage.Id
    ]
    .ContentDocumentId;

    breadwinner_ns__BW_Item__c netsuiteItem = new breadwinner_ns__BW_Item__c(
      Name = 'Existing Image Test Item',
      imageId__c = previousImageId
    );
    insert netsuiteItem;

    String showImageLink = 'https://example.com/show-image.jpg';
    Test.setMock(
      HttpCalloutMock.class,
      new NetSuiteItemImageRequestMock(showImageLink)
    );

    Test.startTest();
    update new breadwinner_ns__BW_Item__c(
      Id = netsuiteItem.Id,
      ncf_item_show_image_link__c = showImageLink
    );
    Test.getEventBus().deliver();
    Test.stopTest();

    breadwinner_ns__BW_Item__c updatedItem = [
      SELECT imageId__c
      FROM breadwinner_ns__BW_Item__c
      WHERE Id = :netsuiteItem.Id
    ];
    System.assertNotEquals(
      previousImageId,
      updatedItem.imageId__c,
      'The show-image link should replace an existing image when web-image-1 is blank.'
    );
  }

  @IsTest
  static void isImageLinkChangedComparisonTest() {
    breadwinner_ns__BW_Item__c storedItem = new breadwinner_ns__BW_Item__c(
      Name = 'Comparison Test Item'
    );
    insert storedItem;

    NetSuiteItemImageTriggerHandler handler = new NetSuiteItemImageTriggerHandler();
    String originalLink = 'https://example.com/original.jpg';
    String replacementLink = 'https://example.com/replacement.jpg';

    System.assertEquals(
      false,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(Id = storedItem.Id),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(Id = storedItem.Id)
        }
      ),
      'Two null show-image links should be unchanged.'
    );

    System.assertEquals(
      true,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(
          Id = storedItem.Id,
          ncf_item_show_image_link__c = originalLink
        ),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(Id = storedItem.Id)
        }
      ),
      'Adding a show-image link should be detected.'
    );

    System.assertEquals(
      true,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(
          Id = storedItem.Id,
          ncf_item_show_image_link__c = replacementLink
        ),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(
            Id = storedItem.Id,
            ncf_item_show_image_link__c = originalLink
          )
        }
      ),
      'Replacing a show-image link should be detected.'
    );

    System.assertEquals(
      false,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(Id = storedItem.Id),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(
            Id = storedItem.Id,
            ncf_item_show_image_link__c = originalLink
          )
        }
      ),
      'Clearing a show-image link should not trigger image loading.'
    );

    System.assertEquals(
      true,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(
          Id = storedItem.Id,
          ncf_item_show_image_link__c = originalLink,
          ncf_item_web_image1_link__c = replacementLink
        ),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(
            Id = storedItem.Id,
            ncf_item_show_image_link__c = originalLink,
            ncf_item_web_image1_link__c = originalLink
          )
        }
      ),
      'Changing to a nonblank web-image-1 link should be detected.'
    );

    System.assertEquals(
      false,
      handler.isImageLinkChanged(
        new breadwinner_ns__BW_Item__c(
          Id = storedItem.Id,
          ncf_item_show_image_link__c = originalLink
        ),
        new Map<Id, breadwinner_ns__BW_Item__c>{
          storedItem.Id => new breadwinner_ns__BW_Item__c(
            Id = storedItem.Id,
            ncf_item_show_image_link__c = originalLink,
            ncf_item_web_image1_link__c = originalLink
          )
        }
      ),
      'Clearing web-image-1 while show-image is unchanged should not trigger image loading.'
    );
  }

  @IsTest
  static void coverImageLoaderBatchJob() {
    insert new breadwinner_ns__BW_Item__c();

    Test.setMock(HttpCalloutMock.class, new NetSuiteItemImageRequestMock(null));

    Test.startTest();
    new NetSuiteItemImageLoaderBatch().execute(null);
    Test.stopTest();
  }

  class NetSuiteItemImageRequestMock implements System.HttpCalloutMock {
    private String expectedEndpoint;

    NetSuiteItemImageRequestMock(String expectedEndpoint) {
      this.expectedEndpoint = expectedEndpoint;
    }

    public HttpResponse respond(System.HttpRequest req) {
      if (expectedEndpoint != null) {
        System.assertEquals(
          expectedEndpoint,
          req.getEndpoint(),
          'The loader selected the wrong image endpoint.'
        );
      }
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBodyAsBlob(Blob.valueOf('test'));
      return res;
    }
  }
}
