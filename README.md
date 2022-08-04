# CodePipes CI/CD Modules

This repository contains the pipeline modules that are used by various backend services of CodePipes.

## pipeline-module

A pipeline-module is a fraction of cloud-native CI/CD tool definition.
Multiple pipeline-modules are stitched together in the backend to form one CI/CD pipeline and is executed on the user's cloud account.

A pipeline-module is defined in YAML format. The format consists of fields that gets rendered on the UI for end-user as well as there are fields that provides definition that makes the actual execution possible.

YAML fields reference:


| Field | type | description |
|--------|--------|--------|
| provisioner | string |  Provisioner is the target environment (e.g. gcp) this module is compatible with. |
| name | string |  Name by which it is referenced in a pipeline (e.g. sign-binary). Each module family may have one or more versions. |
| version | uint16 |  Versions may vary in both behavior and API. Each module version may have one or more revisions. |
| revision | uint16 |  Revisions are internal implementation versions (e.g. bugfixes) with identical behavior and API. |
| displayName | string |  Display name. |
| description | string |  Display description. |
| target | string |  Target artifact(s) of this module (e.g. language). |
| keywords | []string |  Lookup keywords. |
| author | string |  Maintainer. |
| meta | object |  Metadata related to pipeline module |
| inputs | InputsSchema | [JsonSchema](http://forivall.com/json-schema-cheatsheet/) defining input fields required in the module |
| template | string |  Template of cloud-native implementation code. This template rendered with user inputs can be executed by the provisioner. |

### InputsSchema

JsonSchema defining input fields required in the module. Use this cheat-sheet for quick reference: http://forivall.com/json-schema-cheatsheet/

We have a few modifications in the schema syntax to meet some custom requirements:

#### - **Top element is always an object**

Because input to the pipeline module template is always an object

#### - **internal** ([]string)

An attribute used for object type field to mark a set of fields for internal use and not render on UI for end-user.
example:

```yaml
inputs:
    properties:
        X: ...
        Y: ...
        a: ...
        b: ...
    internal:
        - a
        - b
```
This will render only `X` & `Y` on UI form not `a` & `b`

### Template

The template field defines the cloud native build template.
This template can also make use of the module inputs defined into the input section by the means of Django 1.7 syntax such that it renders into the cloud native template format.

We use [Pongo2](https://github.com/flosch/pongo2) to render the templates which is based on [Django 1.7](https://django.readthedocs.io/en/1.7.x/topics/templates.html)

For Django built-in filters, refer this: https://django.readthedocs.io/en/1.7.x/ref/templates/builtins.html#ref-templates-builtins-filters

We also have custom filters for available for the template. our custom filter have `cpi_` prefix. And the documentation can be found here: https://github.com/cldcvr/vanguard-api/blob/master/pkg/pipeline/custom_filters.md