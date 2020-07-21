# Profile

In KARNAK on the profile page, you can upload your custom profile.

A profile in KARNAK is a list of different profile or action defined on a scope of tags. During the de-identification, KARNAK will built this list and apply to a tag and its value each profile in the list. If a profile apply his action on a tag, KARNAK will move on to the next tag. So if the first profile used the tag, the next profile will never be called on that tag.

Currently the profile must be a yaml file (MIME-TYPE: **application/x-yaml**) and respect the definition as below.

## Metadata

The "headers" of the profile are this metadata. All this headers are optional, but for a better user experience we recommend that set the name to a minimum.

`name` - The name of your profile.

`version` - The version of your profile.

`minimumkarnakversion` - The version of KARNAK when the profile has been built.

`defaultIssuerOfPatientID` - this value is used to built the patient's pseudonym.

`profiles` - The list of profile applied on the desidentification. The first profile of this list is first called.

## Profile

A profile is defined as below in the yaml.

`name` - The name of your profile

`codename` - The profile has been applied (Must exist in KARNAK)). The list of possible profiles is defined below.

`action` - The action to apply to the profile. For example K (keep), X (remove)

`tags` - List of tags for the current profile. The action defined in the profile will be applied on this list of tags.

`exceptedtags` - This list represents the tags where the action will not be applied. This means that if a tag defined in this list appears for this profile, it will give control to the next profile.

### Tag

The tags can be defined on different format: `(0010,0010)`; `0010,0010`; `00100010`;

A tag pattern can be defined as below: `(0010,XXXX)` groups all these tags `(0010, [0000-FFFF])`

### codename

`basic.dicom.profile` is the [basic profile defined by DICOM](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_E.html). This profile applied the action defined by DICOM on the tags that identifies.

**We strongly recommend to use this profile systematically**

This profile need this parameters:

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

This profile need this parameters:

* name
* codename
* action
* tags

This profile can have these optional parameters:

* exceptedtags

In this example, all tags starting with 0028 will be removed excepted (0028,1199) which will be kept.

```
- name: "Remove tags"
  codename: "action.on.specific.tags"
  action: "X"
  tags:
    - "(0028,xxxx)"
  exceptedtags:
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
* exceptedtags

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
minimumkarnakversion: "0.1"
defaultIssuerOfPatientID: "DPA"
profiles:
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

