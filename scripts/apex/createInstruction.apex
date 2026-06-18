String instructionInternalId = InstructionController.saveInstruction(
  '187027',
  '2407139',
  'This is a test instruction!'
);

String commentInternalId = CommentController.saveComment(
  '187027',
  '2407139',
  'This is a test comment!'
);

String fileDataJson = JSON.serialize(new Map<String, Object>{
  'name' => 'STD claim packet.pdf',
  'documentId' => '069WJ00000F8LeXYAV',
  'contentVersionId' => '068WJ00000FyskrYAB',
  'contentBodyId' => '05TWJ00000PvrCU2AZ',
  'mimeType' => 'application/pdf'
});

NsFileDataModel.UploadFileResult result = NsFileController.uploadFile(
  'test file caption',
  '29448',
  fileDataJson
);

