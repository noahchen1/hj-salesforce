// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);

String ACCOUNT_ID = '1783773';
String FOLDER_ID = '16264';

HttpRequest testReq = new HttpRequest();

String testEntPoint =
  'callout:IContact' +
  '/icp/a/' +
  ACCOUNT_ID +
  '/c/' +
  FOLDER_ID +
  '/contacts/';

testReq.setEndpoint(testEntPoint);
testReq.setMethod('GET');
testReq.setHeader('Accept', 'application/json');
testReq.setHeader('Content-Type', 'application/json');
testReq.setHeader('API-Version', '2.2');

Http http = new Http();

HttpResponse res = http.send(testReq);

System.debug('Icontact Response: ' + res.getBody());
