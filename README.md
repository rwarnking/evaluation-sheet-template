# PDF games

[<img alt="Build status" src="https://img.shields.io/github/workflow/status/rwarnking/evaluation-sheet-template/Create%20PDFs?label=Build&logo=github&style=for-the-badge" height="23">](https://github.com/rwarnking/pdf-games/actions/workflows/compile.yml)
[<img alt="Linting status of master" src="https://img.shields.io/github/workflow/status/rwarnking/evaluation-sheet-template/Lint%20Code%20Base?label=Linter&style=for-the-badge" height="23">](https://github.com/marketplace/actions/super-linter)
[<img alt="Version" src="https://img.shields.io/github/v/release/rwarnking/evaluation-sheet-template?style=for-the-badge" height="23">](https://github.com/rwarnking/evaluation-sheet-template/releases/latest)
[<img alt="Licence" src="https://img.shields.io/github/license/rwarnking/evaluation-sheet-template?style=for-the-badge" height="23">](https://github.com/rwarnking/evaluation-sheet-template/blob/main/LICENSE)

## Description
This is a LaTeX template to generate evaluation sheets.
Given data about the participants and the assignments this template automatically
generates the PDF and adjusts the layout accordingly.

## Table of Contents
1. [List of Features](#list-of-features)
1. [Installation](#installation)
2. [Usage](#usage)
3. [Contributing](#contributing)
4. [Credits](#credits)
4. [License](#license)

## List of Features

- Select from two layouts
- Process a list of participants
- Process a list of assignments

For a more detailed explanation about this project, take a look into the
[wiki](https://github.com/rwarnking/evaluation-sheet-template/wiki) of this project.
There you can also find information about the syntax of the different files.

## Installation

To use the template and generate a evaluation sheet yourself you need a LaTeX distribution
e.g. [TeX Live](https://www.tug.org/texlive/) and the required packages.

<!--
Alternativly you can use one of the install scripts
([bash](https://github.com/rwarnking/evaluation-sheet-template/blob/main/install.sh) |
[powershell](https://github.com/rwarnking/evaluation-sheet-template/blob/main/install.ps1))
to install all dependencies and the acrotex package automatically.
-->

### Dependencies

These packages are needed:
- [table](https://ctan.org/pkg/insdljs)
- [dvipsnames](https://ctan.org/pkg/insdljs)
- [listings](https://ctan.org/pkg/insdljs)
- [enumitem](https://ctan.org/pkg/insdljs)
- [pgffor](https://ctan.org/pkg/insdljs)
- [xinttools](https://www.ctan.org/pkg/xint)
- [xintfrac](https://ctan.org/pkg/insdljs)
- [forloop](https://ctan.org/pkg/insdljs)
- [calc](https://ctan.org/pkg/insdljs)
- [tikz](https://ctan.org/pkg/insdljs)
- [csvsimple](https://ctan.org/pkg/insdljs)

These packages are also needed but should usually be installed by default:
- [inputenc](https://ctan.org/pkg/insdljs)
- [geometry](https://www.ctan.org/pkg/geometry)
- [array](https://ctan.org/pkg/insdljs)
- [tabularx](https://www.ctan.org/pkg/tabularx)

## Usage

Simply compile the `.tex` file to PDF.

## Contributing

I encourage you to contribute to this project, in form of bug reports, feature requests
or code additions. Although it is likely that your contribution will not be implemented.

Please check out the [contribution](docs/CONTRIBUTING.md) guide for guidelines about how to proceed
as well as a styleguide.

## Credits
Up until now there are no further contributors other than the repository creator.

## License
This project is licensed under the [MIT License](LICENSE)
