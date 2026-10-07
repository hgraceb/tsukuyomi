## Unreleased

* Store fields and injected source properties per instance, and evaluate each object's field initializers in Dart inheritance order during construction.
* Fix bare `return;` yielding a leftover stack value instead of `null`, including async functions and nested scopes.
* Complete async functions with their uncaught errors, preserve rethrow stack traces, and restore VM state when native callbacks throw.
* Clean up loop body locals and captured values on `break` and `continue`, and discard each `for` updater result.
* Give variables declared in a `for` initializer fresh closure bindings before each updater, including loops without updaters and `continue` paths.

## 0.0.1

* Initial release.
