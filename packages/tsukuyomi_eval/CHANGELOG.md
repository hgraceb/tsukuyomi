## Unreleased

* Fix bare `return;` yielding a leftover stack value instead of `null`, including async functions and nested scopes.
* Complete async functions with their uncaught errors, preserve rethrow stack traces, and restore VM state when native callbacks throw.

## 0.0.1

* Initial release.
