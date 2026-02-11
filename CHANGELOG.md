## 4.1.0

- Breaking: Renamed constructors for clarity
    - `DC.data()` → `DC.some()` (explicitly wraps in Some)
    - `DC.nullData()` → `DC.none()` (explicitly creates None)
- Breaking: Renamed factory methods
    - `Option.from()` → `Option.auto()` (auto-detects null)
- New: `DC.auto(nullableData)` - automatically creates Some or None based on null check
- New: `DC.fromOption(option)` - lifts existing Option into DC without double-wrapping

## 4.0.0+3

- Downgrade meta to 1.17.0 for Flutter test compatibility

## 4.0.0+2

- Readme updates

## 4.0.0+1

- Readme updates

## 4.0.0

- Requires Dart 3.0+ for sealed class support
- Breaking: Complete API redesign - removed `pick()`, `mapData()`; added `fold()`, `forwardErrorOr()`,
  `forwardErrorOrElse()`
- Breaking: `DCData` now contains `Option<Data>` (Some/None pattern) instead of nullable types
- New: `mapError()` for error transformations, comprehensive Option API for null-safety

## 3.0.0+2

- Changelog updates

## 3.0.0+1

- Readme updates

## 3.0.0

- Added `fold` method for exhaustive pattern matching with required handlers
- Added `mapData` method to transform successful data while preserving errors
- Added `mapError` method to transform errors while preserving data
- Improved type safety and null handling
- Enhanced documentation with additional examples

## 2.0.0+1

- Added null safety

## 1.0.4+1

- Fixed 'Dart_LoadScriptFromKernel: The binary program does not contain main' bug

## 1.0.3

- Description updates

## 1.0.0

- Initial release
