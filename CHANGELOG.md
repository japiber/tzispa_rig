Tzispa Rig

Rig templates implementation

## v0.2.5
- Add template methods for use in cli

## v0.2.4
- allow loop_item binder without parameters

## v0.2.3
- Fix in the api call regex syntax
- Added prefix in api calls

## v0.2.2
- Bug fix in iblk render
- Remake of the Binder class defining two specialized classes: TemplateBinder and LoopBinder
- Bug fix and improvements in the statements parser
- Bug fix in the loop_binder method not allowing 2 loops with equal ids at the same level

## v0.2.1
- Regexp optimizations
- Some classes has been renamed for better code readability

## v0.2.0
- Implemented new parser to break away parsing and rendering
- Implemented template caching class 'Engine' with on demand parsing: a block template is parsed only when if it's new or if it has been modified

## v0.1.0
- Initial release: code moved from tzispa main gem
