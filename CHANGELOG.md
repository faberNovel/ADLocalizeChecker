# Change Log
All notable changes to this project will be documented in this file.
`LocalizeChecker` adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.7.0] - 2021-01-18

### Fixed
- prepare pod for public release

### Added
- add generic key test
- complete LocalizeCheckerCoreTests
- handle carriage returns and unicode newlines in keys

## [0.6.4]

### Added
- handle bad arguments format check in formatted keys

## [0.6.3]

### Fixed
- fix false negative keyToBypass
- fix last occurence line number in file for formatted keys
- fix duplicated occurence of pattern check

## [0.6.2]

### Added
- handle padding formats

### Fixed
- use keyToBypass in all errors

## [0.6.1]

### Fixed
- fix argument's count for ADUtils formatted atrributed strings

## [0.6.0]

### Updated
- add target management in LCRelativeToTargetLocalizableBaseFolder

### Added
- add LCKeysToBypass in plist
- handle ADUtils.attributedString(arguments: defaultAttributes: formatAttributes:)

## [0.5.2]

### Fixed
- add current count in formatted bad arguments count error

## [0.5.1]

### Fixed
- handle parameters in stringWithFormat arguments

## [0.5.0]

### Added
- formatted keys management
- bypass-generic-error

### Fixed
- clean error's line number and messages

## [0.4.0]

### Updated
- update librairies

### Fixed
- the pod can be used as a real pod, not only a dev pod
- unusedKeyInMainLanguage error
- s3 upload path
- supportedLanguages for Pods

## [0.3.0]

### Added
- Swift Package Manager
- Makefile
- Zip upload to S3
- Core module
- PList parameter

## [0.2.0]

### Fixed
- Podspec url

## [0.1.0]

Localize.swift is based on https://github.com/freshOS/Localize

### Added
- add pods, multi target, logs, error option, stringsDict
- defaut language from CFBundleDevelopmentRegion
- add some patterns: badFormatPatterns, errorPatterns, defaultPatterns
- formattableCharacters

### Updated
- code syntax (force unwrap, cast, line length etc)
- ignoredPattern, make all patterns arrays

### Removed
- find and replace script to remove dead keys all at once!
- sortLinesAlphabetically and removeEmptyLinesFromFile
