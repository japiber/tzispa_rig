Tzispa Rig

Rig templates implementation

## v0.5.9
- classes constants autoloading

## v0.5.8
- engine class renamed to factory

## v0.5.6
- bugs fix

## v0.5.5
- minor code refactory
- move template creation code to helper module

## v0.5.4
- fix nested loops not binding

## v0.5.3
- added before/after hooks in template binders

## v0.5.2
- replace lru_redux with moneta to improve template cache storage
- added fallback to super in method_missing at LoopBinder
- support for bind data from json

## v0.5.1
- Bug fixes and code refactoring

## v0.5.0
- Rig templates syntax changes in url/purl and blk/iblk/static
- Added support for subdoamins in layouts
- new rig engine interface now shared by all apps
- added some testing with minitest
- escape (by content type) var tags values before render
- allow recursive template block calls
- code refactoring & templates namespace simplification
- rig-parser implementation improvements

## v0.4.5
- code fixes for replacing TzString with String refinement

## v0.4.4
- add session,router_params,not_found&logger delegators to make template binders less contextized
- remove unused gem dependencies and code (old parser)

## v0.4.3
- add config and repository delegators into context
- updated rig templates documentation

## v0.4.2
- add support for metavars in purl/url tag id

## v0.4.1
- add inter-app calls for url and api tags

## v0.4.0
- add suport for signed/unsigned api calls

## v0.3.4
- fix template cache returning empty template sometimes

## v0.3.3
- Raise a custom exception when a binder tag does not exists in the template
- Raise custom exception when there are duplicated loops in binder

## v0.3.2
- Fix error bad format parameter when engine template cache is disabled

## v0.3.1
- Fix error in engine template cache that was losing template params when a template was recovered from cache

## v0.3.0
- Separate engine class into independant ruby file
- Move rig url builder tags into independant parser category
- Now static blocks can parse url builder tags: url, purl & api

## v0.2.9
- Fix bugs in template cache engine causing modified template files are not reloading
- Replaces Tzispa::Utils::Cache with lru_redex gem

## v0.2.7
- Add url template tag to build canonical urls

## v0.2.6
- Add basic documentation

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
