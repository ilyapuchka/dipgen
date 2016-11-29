# CHANGELOG

## 1.0.2

* Added parsing tag in `implements` annotation. Use `@dip.implements Type(tag)` to generate `.implements(Type.self, tag: "tag")` code.  
* Added using `init()` as default constructors for components annotated with `storyboardInstantiatable`

#### Fixed

* Fixed generating scope values
* Fixed detecting a single constructor as designated
* Fixed constructors ambiguity by always using closure syntax for registration
* Fixed warnings for unneded casts of resolved instances

## 1.0.1

* Added `--no-factories` option to skip generating factories

## 1.0.0

Initial release
