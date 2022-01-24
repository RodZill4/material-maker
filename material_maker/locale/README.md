# Localization files for Material Maker

More information in the Godot documentation:
[Localization using gettext](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html)

## Setup

### Install gettext tools

*This step is required if you wish to create a new translation, check
translation files' syntax for errors or update translations to match the
translation template.*

- **Windows:** Download an installer from [this page](https://mlocati.github.io/articles/gettext-iconv-windows.html).
  Any architecture and binary type (shared or static) works; if in doubt,
  choose the 64-bit static installer.
- **macOS:** Install [Homebrew](https://brew.sh) then run `brew install gettext`.
- **Linux:** Install `gettext` from your distribution's package manager.
  The package name may differ depending on your distribution.

### Install pybabel

*This step is only required if you wish to regenerate the PO template (see Tasks
below). As a translator, you generally won't have to regenerate the PO template.*

Install Python 3.7 or later and pip then run the following command in a
terminal:

```text
pip3 install --user --upgrade -r requirements.txt
```

## Tasks

### Create a new translation

Run `./create_translation.sh <language code>` where `<language code>` is a
language code such as `fr`, `de`, `es`, …

## Check translation files' syntax for errors

Run `./check.sh`.

### Update the translation template

Run `./generate_po_template.sh`. Don't edit the generated `material-maker.pot`
file manually as changes will be overwritten next time the PO template is
generated.

### Update translations to match the translation template

Run `./merge.sh`. New strings will be added, modified strings will have a
`fuzzy` marker added. You should review the strings in the translated file and
remove the `fuzzy` marker after reviewing them.
