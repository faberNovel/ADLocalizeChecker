LOCALIZE_CHECKER_EXECUTABLE=$(shell swift build --configuration release --show-bin-path)/LocalizeChecker
LOCALIZE_CHECKER_DEBUG_EXECUTABLE=$(shell swift build --show-bin-path)/LocalizeChecker
EXAMPLE_EXECUTABLE_PATH=Example/LocalizeChecker
ZIP_FILE=LocalizeChecker.zip

build:
	swift build

clean:
	rm -rf .build 2>/dev/null
	rm -f $(ZIP_FILE) 2>/dev/null
	rm -f LocalizeChecker 2>/dev/null

release:
	swift build --configuration release
	cp $(LOCALIZE_CHECKER_EXECUTABLE) .
	zip -r $(ZIP_FILE) LocalizeChecker

test:
	swift test

proj:
	swift package generate-xcodeproj

examplebuild:
	make build
	cp $(LOCALIZE_CHECKER_DEBUG_EXECUTABLE) $(EXAMPLE_EXECUTABLE_PATH)
