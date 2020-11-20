# Profile

In the Karnak user interface, you can click on the Profile button on the left. This allows you to see the list of profiles and to import new profiles.

A profile file is one or a list of profile elements that are defined for a group of DICOM attributes and with a particular action. During de-identification, Karnak will apply the profile elements to all applicable DICOM attributes. The principle is that it is not possible to apply multiple profile elements to a DICOM attribute. The profile elements are applied in the order defined in the yaml file and, therefore, it is the first applicable profile element that will modify the value of a DICOM attribute and the following profile elements will not be applied.

Currently, the profile must be a yaml file (MIME-TYPE: **application/x-yaml**) and respect the definition as below.

## Profile metadata

All these metadata are optional, but for a better user experience we recommend defining at least the name and the version.

`name` - The name of your profile.

`version` - The version of your profile.

`minimumKarnakVersion` - The version of Karnak when the profile has been built.

`defaultIssuerOfPatientID` - this value will be used to build the patient's pseudonym when IssuerOfPatientID value is not available in DICOM file.

`profileElements` - The list of profile element applied on the de-identification. The first profile element of this list is first called.

## Profile element

A profile element is defined as below in the yaml file.

`name` - The name of your profile element

`codename` - The ID of the profile element. It must related to the list profile elements defined below.

`action` - The action to apply to the profile element. For example K (keep), X (remove)

`option` - Some profiles contain option.

`arguments` - Some profiles contain one or more arguments. Arguments is a list that contain a key and a value.

`tags` - List of tags for the current profile. The action defined in the profile will be applied on this list of tags.

`excludedTags` - This list represents the tags where the action will not be applied. This means that if a tag defined in this list appears for this profile, it will give control to the next profile.

### Tag

DICOM Tags can be defined in different formats: `(0010,0010)`; `0010,0010`; `00100010`;

A tag pattern represent a group of tags and can be defined as follows: e.g. `(0010,XXXX)` represent all the tags of group 0010.

### codename

---

`basic.dicom.profile` is the [basic profile defined by DICOM](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_E.html). This profile applied the action defined by DICOM on the tags that identifies.

**We strongly recommend including this profile as basis for de-identification.**

This profile element requires the following parameters:

```yaml
- name: "DICOM basic profile"
  codename: "basic.dicom.profile"
```

---

`action.on.specific.tags` is a profile that apply a action on a group of tags defined by the user. The action possible is:
* K - keep
* X - remove

This profile element requires the following parameters:

* name
* codename
* action
* tags

This profile element can have these optional parameters:

* excludedTags

In this example, all tags starting with 0028 will be removed excepted (0028,1199) which will be kept.

```yaml
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

---

`action.on.privatetags` is a profile that apply a action given on all private tags or a group of private tags defined by the user. If the tag given isn't private, the profile will not be called. The action possible is:

* K - keep
* X - remove

This profile element requires the following parameters:

* name
* codename
* action

This profile can have these optional parameters:

* tags
* excludedTags

In this example, all tags starting with 0009 will be kept and all private tags will be deleted.

```yaml
- name: "Keep private tags starint with 0009"
  codename: "action.on.privatetags"
  action: "K"
  tags:
    - "(0009,xxxx)"

- name: "Remove all private tags"
  codename: "action.on.privatetags"
  action: "X"
```

---

`action.on.dates` is a profile element that applies actions on dates. This profile element contains several options and  will be executed only on the following VR types: AS, DA, DT ,TM.

This profile need this parameters:

* name
* codename
* option

This profile element need one of this options:

* shift
* shift_range
* date_format

This profile element can have these optional parameters:

* tags
* excludedTags

Below, the examples with the different possible options

1.  **shift** option allows to shift a date according to the following arguments:

* seconds (required)
* days (required)

In this example, all the tags starting with 0010 and that are date fields are offset by 30 seconds and 10 days.

```yaml
  - name: "Shift Date"
    codename: "action.on.dates"
    arguments:
      seconds: 30
      days: 10
    option: "shift"
    tags:
      - "0010,XXXX"
```

2. **shift_range** option allows to shift a date according to a date range according to the following arguments:

- max_seconds (required)
- max_days (required)
- min_seconds (Optional)
- min_days (Optional)

In this example, all the tags starting with 0008,002 and that are date fields are shifted randomly in a range of maximum second 60 maximum days 100 and minimum days 50. For each same patient belonging to the same project the random value shifted randomly will always be the same (For more details about the project and the Karnak random, see [Karnak Doc](https://github.com/OsiriX-Foundation/karnak/tree/master/doc))


```yaml
  - name: "Shift Range Date"
    codename: "action.on.dates"
    arguments:
      max_seconds: 60
      min_days: 50
      max_days: 100
    option: "shift_range"
    tags:
      - "0008,002X"
```

3. **date_format** option allows you to delete the days or the month and days.

With this example profile element, a tag value contains this entry date for example  `20140504 `  with the argument key  `remove ` and value  `month_day `, will have this output date  `20140101`.

```yaml
  - name: "Date format"
    codename: "action.on.dates"
    arguments:
      remove: "month_day"
    option: "date_format"
    tags:
      - "0008,003X"
```

With this example profile element, a tag value contains this entry date for example  `20140504 `  with the argument key  `remove ` and value  `month_day `, will have this output date  `20140501`.

```yaml
  - name: "Date format"
    codename: "action.on.dates"
    arguments:
      remove: "day"
    option: "date_format"
    tags:
      - "0008,003X"
```

---

## A full example of profile

This example remove two tags not defined in the basic DICOM profile, keep the Philips PET private group and apply the basic DICOM profile.

The tag 0008,0012 is Instance Creation Date and the tag 0008,0013 is Instance Creation Time.

The tag pattern (0073,xx00) and (7053,xx09) are defined in [Philips PET Private Group by DICOM](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/sect_E.3.10.html).

```yaml
name: "Profile Example"
version: "1.0"
minimumKarnakVersion: "0.9.2"
profileElements:
  - name: "Remove tags 0008,0012; 0008,0013"
    codename: "action.on.specific.tags"
    action: "X"
    tags:
      - "0008,0012"
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

