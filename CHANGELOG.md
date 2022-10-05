# Changelog

## [0.1.1] - 2022-10-05

### Fixes

 * Adds callback ordering for functions to support multiple callbacks
 * Only consolidate function clause header, function body should be kept
   in the original module

Consolidated files with both function header and body works OK for
trivial cases. The original module/function body may contain aliases,
use/import etc, these will not be available in the consolidated module.
Performing a remote call resolves any issues with the added bonus of
providing better stacktraces.

## [0.1.0] - 2022-10-02

### Added

Minimal compiler and dispatch functionality.
