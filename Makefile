clean:
	@# just delete specific directories instead of .builds so we don't
	@# have to re-fetch dependencies
	@rm -f .build/debug
	@rm -rf .build/*-apple-macosx/
	@rm -rf .build/*-unknown-linux/
	@rm -rf .build/*-unknown-linux-gnu/

macos-5.5: clean
	@echo
	@echo === Building $@ ===
	env DEVELOPER_DIR=/Applications/Xcode-13.2.1.app xcrun swift build

macos-5.6: clean
	@echo
	@echo === Building $@ ===
	env DEVELOPER_DIR=/Applications/Xcode-13.4.1.app xcrun swift build

macos-5.7: clean
	@echo
	@echo === Building $@ ===
	env DEVELOPER_DIR=/Applications/Xcode-14.2.0.app xcrun swift build

linux-5.5: clean
	@echo
	@echo === Building $@ ===
	docker run --rm -v "$(PWD)":/host -w /host "swift:5.5-focal" swift build

linux-5.6: clean
	@echo
	@echo === Building $@ ===
	docker run --rm -v "$(PWD)":/host -w /host "swift:5.6-focal" swift build

linux-5.7: clean
	@echo
	@echo === Building $@ ===
	docker run --rm -v "$(PWD)":/host -w /host "swift:5.7-focal" swift build

linux: clean \
	linux-5.5 \
	linux-5.6 \
	linux-5.7

macos: clean \
	macos-5.5 \
	macos-5.6 \
	macos-5.7

all: clean \
	macos \
	linux
