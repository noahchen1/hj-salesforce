List<Map<String, String>> users = new List<Map<String, String>>{
  new Map<String, String>{
    'FirstName' => 'Pton',
    'MiddleName' => '',
    'LastName' => 'Jeweler',
    'Email' => 'ptonjeweler@hamiltonjewelers.com'
  },
  new Map<String, String>{
    'FirstName' => 'Richard',
    'MiddleName' => '',
    'LastName' => 'LeBlanc',
    'Email' => 'rleblanc@hamiltonhome.com'
  },
  new Map<String, String>{
    'FirstName' => 'Richard',
    'MiddleName' => '',
    'LastName' => 'Telesco',
    'Email' => 'rtelesco@hamiltonjewelers.com'
  },
  new Map<String, String>{
    'FirstName' => 'Sabrina',
    'MiddleName' => '',
    'LastName' => 'Nandram',
    'Email' => 'snandram@hamiltonjewelers.com'
  },
  new Map<String, String>{
    'FirstName' => 'Shannon',
    'MiddleName' => '',
    'LastName' => 'Henry',
    'Email' => 'shenry@hamiltonjewelers.com'
  },
  new Map<String, String>{
    'FirstName' => 'Ted',
    'MiddleName' => '',
    'LastName' => 'Arnstein',
    'Email' => 'tarnstein@hamiltonjewelers.com'
  },
  new Map<String, String>{
    'FirstName' => 'Yvonne',
    'MiddleName' => '',
    'LastName' => 'Eng',
    'Email' => 'yeng@hamiltonjewelers.com'
  }
};

String commonTitle = 'Sales Associate';
String commonProfile = 'Standard User';
String commonRole = 'Sales Associate';

Map<String, Integer> aliasCounts = new Map<String, Integer>();

for (Map<String, String> row : users) {
  String firstName = row.get('FirstName');
  String middleName = row.get('MiddleName');
  String lastName = row.get('LastName');
  String email = row.get('Email');

  String baseAlias = ((String.isBlank(firstName) ? '' : firstName.left(1)) +
    (String.isBlank(lastName) ? '' : lastName))
    .toLowerCase()
    .replaceAll('[^a-z0-9]', '');

  if (String.isBlank(baseAlias)) {
    baseAlias = email.split('@')[0].toLowerCase().replaceAll('[^a-z0-9]', '');
  }
  if (baseAlias.length() > 8) {
    baseAlias = baseAlias.substring(0, 8);
  }

  Integer aliasNum = aliasCounts.containsKey(baseAlias)
    ? aliasCounts.get(baseAlias) + 1
    : 1;
  aliasCounts.put(baseAlias, aliasNum);

  String aliasFinal = baseAlias;
  if (aliasNum > 1) {
    String suffix = String.valueOf(aliasNum);
    Integer maxBaseLen = 8 - suffix.length();
    String trimmedBase = baseAlias.length() > maxBaseLen
      ? baseAlias.substring(0, maxBaseLen)
      : baseAlias;
    aliasFinal = trimmedBase + suffix;
  }

  AddUser.Payload payload = new AddUser.Payload();
  payload.FirstName = firstName;
  payload.MiddleName = middleName;
  payload.LastName = lastName;
  payload.Alias = aliasFinal;
  payload.Email = email;
  payload.Username = email;
  payload.Title = commonTitle;
  payload.Profile = commonProfile;
  payload.UserRole = commonRole;
  payload.IsActive = true;
  payload.UserPermissionsInteractionUser = true;

  AddUser.addNewUser(payload);
}
