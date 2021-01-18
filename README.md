# ADLocalizeChecker

## Example

To run the example project:
 - clone the repo.
 - run `bundle install` and  `cd Example && bundle exec pod install` 

 To use the example project in developpement mode:
 - run `bundle install` and  `make examplebuild` from root folder.
 - cd  `Example/`
 - go to the build phases to update the Localization Sanity Check script:
    replace `${PODS_ROOT}/ADLocalizeChecker/LocalizeChecker` with `${SRCROOT}/LocalizeChecker`
 - use `./LocalizeChecker --help` to see the parameters needed

 ## Usecase

 The library analyse the localized strings from your projet and do a sanity check on them.

## Pod integration

If you installed ADLocalizeChecker via CocoaPods, add a new "Run Script Phase" with:
```
    ${PODS_ROOT}/ADLocalizeChecker/LocalizeChecker ${TARGET_NAME} ${SRCROOT}/*linkTo*/LocalizeChecker.plist
```

LocalizeChecker.plist should contain:
- `LCLogsEnabled`: Bool
```
    Set to YES to enable logs
```
- `LCDefaultLanguageFallback`:  String
```
    Set to your default language - for instance `en`
    Used as a fallback of CFBundleDevelopmentRegion
```
- `LCTreatScriptAsError`: Bool
```
    Set to YES to treat script as error, to NO to treat script as warning
```
- `LCDefaultLocalizableFolder`: String
```
    Set to your default .string folder - usually `Resources/Defaults`
    Used as a fallback of LCRelativeToTargetLocalizableBaseFolder
```
- `LCRelativeToTargetLocalizableBaseFolder`: String
```
    Set to your relative to target .string folder - usually `Resources/`
```
- `LCRelativeSourceFolders`: [String]
```
    Contains all folders in which the script will look for localized keys
```
- `LCPodsVSRelativeLocalizableFolder`: [String: String]
```
    Contains each localized pods with its .string folder path
```
- `LCKeysToBypass`: [String]
```
    Contains all keys that should be bypassed
```
- `LCCustomPatterns`: [String]
```
    Contains all custom patterns for the localisation
    For instance localisationCustomPattern\(@?"(\w+)" in the Example project
```
- `LCUnusedPatterns`: [String]
```
    Contains all custom unused key patterns to bypass unused errors
    For instance bypass-custom-unused-error in the Example project
```

NB: ADLocalize handles comment column for each language.
For instance:
```
    key     | en        |  comment en
    days    | days      |  bypass-untranslated-error
```
This generates the line `"days" = "days"; // bypass-untranslated-error` the the .strings file.
The script can handle `bypass-generic-error`, `bypass-untranslated-error` and `bypass-unused-error` by default.

## License

Created and licensed by FABERNOVEL. Copyright 2021 FABERNOVEL. All rights reserved.
