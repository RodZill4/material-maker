# Contributing to Material Maker

Thank you for your interest in contributing to Material Maker!
Please take a look below before making your first contribution.

## Table of Contents

- [Bug reports and feature suggestions](#bug-reports-and-feature-suggestions)
- [Contributing pull requests](#contributing-pull-requests)
- [Translations](#translations)
- [Financial contributions](#contributing-financially)
- [Contacting the developer](#contacting-the-developer)

## Bug reports and feature suggestions

Bug reports and feature suggestions should be made [here](https://github.com/RodZill4/material-maker/issues).

Before creating a new issue, check if your problem/proposal is already mentioned by using the search function to avoid creating duplicates.

When reporting a bug, make sure to follow the template and provide the following(when possible/if required):
- Material Maker version
- System information(OS, GPU)
- What is expected and what happened instead
- Outputs from the terminal
- A screenshot/video showing the problem
- Project file(if you believe the issue relates to a specific setup)

## Contributing pull requests

Using AI/LLM or any form of agentic coding for your pull request is not allowed.

Use your own words when writing the description. If English is a barrier, consider using a dedicated language service(i.e. [Google Translate](https://translate.google.com/), [DeepL](https://www.deepl.com/en/translator)).

**Using Godot Engine**

Material Maker is built using the Godot Engine using GDScript. As such, it is required to [download the software](https://godotengine.org/) in order to open/test the project. The version used for development can be seen in the [project.godot](https://github.com/RodZill4/material-maker/blob/master/project.godot) file under the `config/features` key.

If you are opening the project in Godot Engine for the first time, Game Embedding must be disabled or else the app may not launch in the editor.

This can be set from the editor settings:

`Run > Window Placement > Game Embed Mode` and setting it to `Disabled`

**Formatting**

Follow the [Godot Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) when formatting your code. Consider looking at surrounding code to copy their patterns and style.

Additionally, 
- Use static typing, and explictly type over inferred typing, i.e. `var my_button : Button = Button.new()` instead of `var my_button := Button.new()`.
- Use a single new-line when separating functions

**PR Workflow**
1. Fork the repository.
2. Setup Git and clone the repository.
2. Create a new branch: `git checkout -b feat-new-panel`
3. Make your changes, and add them using `git add .`
4. Commit your changes: `git commit -m "Implemented new panel"`
5. Push your branch: `git push origin feat-new-panel`
6. Create a new pull request and describe your changes.

If your contribution resolves an existing issue, please add a [Github closing keyword](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue) in the description of your pull request (e.g. - Closes #1234). This will make linked issue(s) to close automatically if your PR is merged.

## Translations

Material Maker provides translation files via an [online registry](https://rodzill4.github.io/material-maker/languages.json) which users can download from within the software.

To contribute to this registry, create your translation file, host it somewhere linkable(i.e. in a github repository) and contact RodZill4 directly, via [Discord](https://discord.gg/PF5V3mFwFM).

Both .csv and .po format are supported. You can use [this script](https://github.com/RodZill4/material-maker/blob/master/material_maker/locale/generate_po_template.gd) to generate a po template and edit your translation using [poedit](https://poedit.com/). Also see this [README.md](https://github.com/RodZill4/material-maker/blob/master/material_maker/locale/README.md).

It might also help to use an existing translation as a basis.

## Contributing financially

Although Material Maker is provided for free, it is still possible to contribute financially to help other costs(such as website hosting) and allow more time to be spent on developing/maintaining the software.

- Joining the [Patreon](https://www.patreon.com/rodzlabs)
- Donating on [Itch.io](https://rodzilla.itch.io/material-maker/purchase)
- Getting a [Steam copy](https://store.steampowered.com/app/4110830/Material_Maker/) and leaving a review

## Contacting the developer

For casual discussion around Material Maker or about contributing, you can find RodZill4 (`@rodzlabs`) on the [Discord](https://discord.gg/PF5V3mFwFM) server.
