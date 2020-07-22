# Profile

In the graphical interface of KARNAK, you can click on the button Profiles. This allows to see the list of profiles and to import new profiles.

A profile file is one or a list of profile elements which are defined for a group of DICOM attributes and with a particular action. During the de-identification, KARNAK will apply the profile elements to all applicable DICOM attributes. The principle is that it is not possible to apply several profile elements on a DICOM attribute.The profile elements are applied in the order defined in the yaml file and therefore it will be the first applicable profile element that will modify the value of a DICOM attribute and the following profile elements will not be applied.

Currently the profile must be a yaml file (MIME-TYPE: **application/x-yaml**) and respect the definition as below.

## Profile metadata

The "headers" of the profile are this metadata. All this headers are optional, but for a better user experience we recommend that set the name to a minimum.

`name` - The name of your profile.

`version` - The version of your profile.

`minimumKarnakVersion` - The version of KARNAK when the profile has been built.

`defaultIssuerOfPatientID` - this value will be used to build the patient's pseudonym when IssuerOfPatientID value is not available in DICOM file.

`profileElements` - The list of profile applied on the desidentification. The first profile of this list is first called.

## Profile element

A profile element is defined as below in the yaml.

`name` - The name of your profile element

`codename` - The ID of the profile element. It must related to the list profile elements defined below.

`action` - The action to apply to the profile element. For example K (keep), X (remove)

`tags` - List of tags for the current profile. The action defined in the profile will be applied on this list of tags.

`excludedTags` - This list represents the tags where the action will not be applied. This means that if a tag defined in this list appears for this profile, it will give control to the next profile.

### Tag

The tags can be defined on different format: `(0010,0010)`; `0010,0010`; `00100010`;

A tag pattern can be defined as below: `(0010,XXXX)` groups all these tags `(0010, [0000-FFFF])`

### codename

`basic.dicom.profile` is the [basic profile defined by DICOM](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_E.html). This profile applied the action defined by DICOM on the tags that identifies.

**We strongly recommend to use this profile systematically**

This profile item need this parameters:

* name
* codename

Example:

```
- name: "DICOM basic profile"
  codename: "basic.dicom.profile"
```

`action.on.specific.tags` is a profile that apply a action on a group of tags defined by the user. The action possible is:
* K - keep
* X - remove

This profile element need this parameters:
profiles
* name
* codename
* action
* tags

This profile element can have these optional parameters:

* excludedTags

In this example, all tags starting with 0028 will be removed excepted (0028,1199) which will be kept.

```
- name: "Remove tags"
  codename: "action.on.specific.tags"
  action: "X"
  tags:
    - "(0028,xxxx)"
  excludedTags:
    - "(0028,1199)"

- name: "Keep tags 0028,1199"
  codename: "action.on.specific.tags"
  action: "K"
  tags:
    - "0028,1199"
```

`action.on.privatetags` is a profile that apply a action given on all private tags or a group of private tags defined by the user. If the tag given isn't private, the profile will not be called. The action possible is:

* K - keep
* X - remove

This profile need this parameters:

* name
* codename
* action

This profile can have these optional parameters:

* tags
* excludedTags

In this example, all tags starting with 0009 will be kept and all private tags will be deleted.

```
- name: "Keep private tags starint with 0009"
  codename: "action.on.privatetags"
  action: "K"
  tags:
    - "(0009,xxxx)"

- name: "Remove all private tags"
  codename: "action.on.privatetags"
  action: "X"
```

## A full example of profile

This example remove two tags not defined in the basic DICOM profile, keep the Philips PET private group and apply the basic DICOM profile.

The tag 0008,0008 is the Image identification characteristics and the tag 0008,0013 is the Instance Creation Time.

The tag pattern (0073,xx00) and (7053,xx09) is defined as [Philips PET Private Group by DICOM](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/sect_E.3.10.html).

```
name: "An Example"
version: "1.0"
minimumKarnakVersion: "0.1"
defaultIssuerOfPatientID: "DPA"
profileElements:
  - name: "Remove tags 0008,0008; 0008,0013"
    codename: "action.on.specific.tags"
    action: "X"
    tags:
      - "0008,0008"
      - "0008,0013"

  - name: "Keep Philips PET Private Group"
    codename: "action.on.privatetags"
    action: "K"
    tags:
      - "(7053,xx00)"
      - "(7053,xx09)"

  - name: "DICOM basic profile"
    codename: "basic.dicom.profile"
```

