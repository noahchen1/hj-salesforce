String internalId = InstructionController.saveInstruction(
  '187027',
  '2407139',
  'This is a test instruction!'
);

String internalId = CommentController.saveComment(
  '187027',
  '2407139',
  'This is a test comment!'
);



NsFileDataModel.UploadFileResult result = NsFileController.uploadFile(
  'test file caption',
  '/services/data/v67.0/sobjects/ContentVersion/068WJ00000C7jspYAB/VersionData',
  '29448',
  'image009.png'
);
