## Unreleased

* Support synchronous collection-for elements in List, Set, and Map literals, preserving loop bindings and surrounding expression operands across nested loops and await.
* Build List, Set, and Map literals incrementally, supporting spread, null-aware spread, and collection-if with ordered evaluation and per-element type checks.
* Support arithmetic and bitwise compound assignment and short-circuiting `??=`, evaluating assignment targets once and reusing existing getter/setter, null-aware, and async paths.
* Support synchronous `for-in` loops with fresh declared bindings per iteration, existing variable assignment, and native iterator access.
* Store fields and injected source properties per instance, and evaluate each object's field initializers in Dart inheritance order during construction.
* Fix bare `return;` yielding a leftover stack value instead of `null`, including async functions and nested scopes.
* Complete async functions with their uncaught errors, preserve rethrow stack traces, and restore VM state when native callbacks throw.
* Clean up loop body locals and captured values on `break` and `continue`, and discard each `for` updater result.
* Give variables declared in a `for` initializer fresh closure bindings before each updater, including loops without updaters and `continue` paths.

## 0.0.1

* Initial release.
