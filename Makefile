.PHONY: help deps gen icons icons-tray icons-app tray-prepare icons-check analyze test test-fast test-unit test-widget test-integration test-shard coverage smoke check check-fast desktop android precommit clean release

APK_DIR = build/app/outputs/flutter-apk
APK_PATH = $(APK_DIR)/codewalk.apk
ANDROID_KEY_PROPERTIES = android/key.properties
ANALYZE_LOG = /tmp/flutter_analyze.log
TEST_JOBS ?= 12
FAST_EXCLUDE_TAGS ?= slow,integration

# TTY detection: suppress verbose output in non-interactive mode (CI/agents)
ifneq ($(shell test -t 1 && echo yes),yes)
    LOG = /tmp/codewalk-make.log
    QUIET = > $(LOG) 2>&1 || (cat $(LOG) && exit 1)
else ifdef VERBOSE
    QUIET =
else
    QUIET =
endif

help:
	@echo "CodeWalk Make Targets"
	@echo ""
	@echo "  make deps       Install dependencies"
	@echo "  make gen        Run build_runner"
	@echo "  make icons      Regenerate all icons (icons-tray + icons-app)"
	@echo "  make icons-tray Regenerate tray icons from tray_mono_master.png"
	@echo "  make icons-app  Regenerate app icons from original.png"
	@echo "  make tray-prepare  Convert black bg to transparent on tray_mono_master*.png"
	@echo "  make icons-check Validate icon artifacts and dimensions"
	@echo "  make analyze    Run static analysis + issue budget gate"
	@echo "  make test       Run full test suite (parallel)"
	@echo "  make test-fast  Run fast tests only (exclude slow/integration tags)"
	@echo "  make test-unit  Run unit + presentation tests only"
	@echo "  make test-widget  Run widget tests only"
	@echo "  make test-integration  Run integration-tagged tests only"
	@echo "  make test-shard SHARD_TOTAL=N SHARD_INDEX=I  Run one sharded test slice"
	@echo "  make coverage   Run tests with coverage + threshold gate"
	@echo "  make smoke      Run integration smoke test against OpenCode server"
	@echo "  make check      deps + gen + analyze + test"
	@echo "  make check-fast deps + gen + analyze + test-fast"
	@echo "  make desktop    Build desktop app for current host OS"
	@echo "  make android    Build Android APK (arm64)"
	@echo "  make precommit  check + android"
	@echo "  make release V=patch|minor|major  Bump version, commit, tag, push"
	@echo "  make clean      Clean and restore dependencies"

deps:
	flutter pub get $(QUIET)

gen:
	dart run build_runner build --delete-conflicting-outputs $(QUIET)

icons: icons-tray icons-app

# Convert black background to transparent on tray_mono_master*.png templates.
tray-prepare:
	@if ! command -v magick >/dev/null 2>&1; then \
		echo "ImageMagick (magick) is required for make tray-prepare."; \
		exit 1; \
	fi
	@for f in assets/images/tray_mono_master*.png; do \
		[ -f "$$f" ] || continue; \
		magick "$$f" -alpha copy -fill white -colorize 100% -resize 512x512\! \
			-strip -define png:compression-level=9 "$$f"; \
		echo "Prepared: $$f"; \
	done

# Derive platform tray icons from fixed tray_mono_master.png template.
icons-tray:
	@if [ ! -f "assets/images/tray_mono_master.png" ]; then \
		echo "Missing fixed tray template: assets/images/tray_mono_master.png"; \
		exit 1; \
	fi
	@if ! command -v magick >/dev/null 2>&1; then \
		echo "ImageMagick (magick) is required for make icons-tray."; \
		exit 1; \
	fi
	magick assets/images/tray_mono_master.png -resize 48x48\! -strip -define png:compression-level=9 assets/images/tray_icon_linux.png
	magick -size 44x44 xc:black \( assets/images/tray_mono_master.png -resize 44x44\! -alpha extract \) -alpha off -compose CopyOpacity -composite -strip -define png:compression-level=9 assets/images/tray_icon_macos_template.png
	magick assets/images/tray_mono_master.png -resize 64x64\! -define icon:auto-resize=64,48,32,24,20,16 assets/images/tray_icon_windows.ico
	@for size_dir in "drawable-mdpi:24" "drawable-hdpi:36" "drawable-xhdpi:48" "drawable-xxhdpi:72" "drawable-xxxhdpi:96"; do \
		dir=$${size_dir%%:*}; size=$${size_dir##*:}; \
		mkdir -p android/app/src/main/res/$$dir; \
		magick -size $${size}x$${size} xc:white \
			\( assets/images/tray_mono_master.png -resize $${size}x$${size}\! -alpha extract -morphology Dilate Disk:1 \) \
			-alpha off -compose CopyOpacity -composite -strip -define png:compression-level=9 \
			android/app/src/main/res/$$dir/ic_stat_codewalk.png; \
	done
	@echo "Tray icons regenerated."

# Derive app icons from original.png (launcher, adaptive, desktop, web).
icons-app:
	@if [ ! -f "assets/images/original.png" ]; then \
		echo "Missing source image: assets/images/original.png"; \
		exit 1; \
	fi
	@if ! command -v magick >/dev/null 2>&1; then \
		echo "ImageMagick (magick) is required for make icons-app."; \
		exit 1; \
	fi
	magick assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 720x775\! -strip -define png:compression-level=9 assets/images/icon.png
	magick assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 256x256\! -strip -define png:compression-level=9 assets/images/logo.256.png
	magick assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 1024x1024\! -strip -define png:compression-level=9 assets/images/logo.1024.png
	magick assets/images/original.png -gravity center -crop 78%x78%+0+0 +repage -resize 1024x1024\! -strip -define png:compression-level=9 assets/images/adaptive_foreground.png
	mkdir -p linux/runner/resources
	magick assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 512x512\! -strip -define png:compression-level=9 \( -size 512x512 xc:none -fill white -draw "roundrectangle 0,0 511,511 72,72" \) -compose CopyOpacity -composite linux/runner/resources/app_icon.png
	cp -f linux/runner/resources/app_icon.png linux/runner/resources/com.verseles.codewalk.png
	printf '%s\n' \
		'[Desktop Entry]' \
		'Version=1.0' \
		'Type=Application' \
		'Name=CodeWalk' \
		'Comment=Cross-platform OpenCode client' \
		'Exec=codewalk %U' \
		'Icon=com.verseles.codewalk' \
		'Terminal=false' \
		'Categories=Development;Utility;' \
		'StartupNotify=true' \
		'StartupWMClass=com.verseles.codewalk' \
		'Keywords=AI;Code;Assistant;OpenCode;' \
		> linux/runner/resources/com.verseles.codewalk.desktop
	magick -size 1024x1024 xc:none \( assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 860x860\! \) -gravity center -composite -define icon:auto-resize=256,128,64,48,32,24,16 windows/runner/resources/app_icon.ico
	magick assets/images/original.png -gravity center -crop 84%x84%+0+0 +repage -resize 1024x1024\! -strip -define png:compression-level=9 \( -size 1024x1024 xc:none -fill white -draw "roundrectangle 0,0 1023,1023 180,180" \) -compose CopyOpacity -composite assets/images/macos_appicon_source.png
	magick assets/images/macos_appicon_source.png -resize 16x16\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
	magick assets/images/macos_appicon_source.png -resize 32x32\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
	magick assets/images/macos_appicon_source.png -resize 64x64\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
	magick assets/images/macos_appicon_source.png -resize 128x128\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
	magick assets/images/macos_appicon_source.png -resize 256x256\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
	magick assets/images/macos_appicon_source.png -resize 512x512\! -strip -define png:compression-level=9 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
	cp -f assets/images/macos_appicon_source.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
	dart run flutter_launcher_icons
	# Web maskable icons with safe zone: keep critical subject inside center area.
	magick -size 512x512 xc:'#7EAFC2' \( assets/images/original.png -gravity center -crop 90%x90%+0+0 +repage -resize 420x420\! \) -gravity center -composite -strip -define png:compression-level=9 web/icons/Icon-maskable-512.png
	magick web/icons/Icon-maskable-512.png -resize 192x192\! -strip -define png:compression-level=9 web/icons/Icon-maskable-192.png
	@echo "App icons regenerated."

icons-check:
	@if ! command -v magick >/dev/null 2>&1; then \
		echo "ImageMagick (magick) is required for make icons-check."; \
		exit 1; \
	fi
	@set -e; \
	for f in \
		assets/images/icon.png \
		assets/images/tray_mono_master.png \
		assets/images/tray_icon_linux.png \
		assets/images/tray_icon_macos_template.png \
		assets/images/tray_icon_windows.ico \
		assets/images/macos_appicon_source.png \
		assets/images/adaptive_foreground.png \
		linux/runner/resources/app_icon.png \
		linux/runner/resources/com.verseles.codewalk.png \
		linux/runner/resources/com.verseles.codewalk.desktop \
		windows/runner/resources/app_icon.ico \
		android/app/src/main/res/drawable-mdpi/ic_stat_codewalk.png \
		android/app/src/main/res/drawable-hdpi/ic_stat_codewalk.png \
		android/app/src/main/res/drawable-xhdpi/ic_stat_codewalk.png \
		android/app/src/main/res/drawable-xxhdpi/ic_stat_codewalk.png \
		android/app/src/main/res/drawable-xxxhdpi/ic_stat_codewalk.png \
		android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png \
		macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png \
		web/icons/Icon-maskable-192.png \
		web/icons/Icon-maskable-512.png; do \
		test -f "$$f" || { echo "Missing icon artifact: $$f"; exit 1; }; \
	done
	@test "$$(magick identify -format '%wx%h' assets/images/icon.png)" = "720x775" || (echo "Invalid assets/images/icon.png size"; exit 1)
	@test "$$(magick identify -format '%wx%h' assets/images/tray_mono_master.png)" = "512x512" || (echo "Invalid tray mono master size"; exit 1)
	@test "$$(magick identify -format '%wx%h' assets/images/tray_icon_linux.png)" = "48x48" || (echo "Invalid Linux tray icon size"; exit 1)
	@test "$$(magick identify -format '%wx%h' assets/images/tray_icon_macos_template.png)" = "44x44" || (echo "Invalid macOS tray template size"; exit 1)
	@magick identify -format '%[opaque]' assets/images/tray_mono_master.png | grep -qi '^false$$' || (echo "Tray mono master must keep transparency"; exit 1)
	@magick identify -format '%[opaque]' assets/images/tray_icon_linux.png | grep -qi '^false$$' || (echo "Linux tray icon must keep transparency"; exit 1)
	@magick identify -format '%[opaque]' assets/images/tray_icon_macos_template.png | grep -qi '^false$$' || (echo "macOS tray template must keep transparency"; exit 1)
	@test "$$(magick identify -format '%wx%h' assets/images/adaptive_foreground.png)" = "1024x1024" || (echo "Invalid assets/images/adaptive_foreground.png size"; exit 1)
	@test "$$(magick identify -format '%wx%h' linux/runner/resources/app_icon.png)" = "512x512" || (echo "Invalid linux app icon size"; exit 1)
	@test "$$(magick identify -format '%wx%h' linux/runner/resources/com.verseles.codewalk.png)" = "512x512" || (echo "Invalid linux app-id icon size"; exit 1)
	@magick identify -format '%[opaque]' linux/runner/resources/app_icon.png | grep -qi '^false$$' || (echo "Linux app icon must keep rounded transparency"; exit 1)
	@magick identify -format '%[opaque]' linux/runner/resources/com.verseles.codewalk.png | grep -qi '^false$$' || (echo "Linux app-id icon must keep rounded transparency"; exit 1)
	@cmp -s linux/runner/resources/app_icon.png linux/runner/resources/com.verseles.codewalk.png || (echo "Linux icon files must stay in sync"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png)" = "16x16" || (echo "Invalid macOS 16x16 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png)" = "32x32" || (echo "Invalid macOS 32x32 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png)" = "64x64" || (echo "Invalid macOS 64x64 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png)" = "128x128" || (echo "Invalid macOS 128x128 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png)" = "256x256" || (echo "Invalid macOS 256x256 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png)" = "512x512" || (echo "Invalid macOS 512x512 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png)" = "1024x1024" || (echo "Invalid macOS 1024x1024 icon"; exit 1)
	@magick identify -format '%[opaque]' macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png | grep -qi '^false$$' || (echo "macOS launcher icon must include rounded transparency"; exit 1)
	@test "$$(magick identify -format '%wx%h' android/app/src/main/res/drawable-mdpi/ic_stat_codewalk.png)" = "24x24" || (echo "Invalid Android mdpi notification icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' android/app/src/main/res/drawable-hdpi/ic_stat_codewalk.png)" = "36x36" || (echo "Invalid Android hdpi notification icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' android/app/src/main/res/drawable-xhdpi/ic_stat_codewalk.png)" = "48x48" || (echo "Invalid Android xhdpi notification icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' android/app/src/main/res/drawable-xxhdpi/ic_stat_codewalk.png)" = "72x72" || (echo "Invalid Android xxhdpi notification icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' android/app/src/main/res/drawable-xxxhdpi/ic_stat_codewalk.png)" = "96x96" || (echo "Invalid Android xxxhdpi notification icon"; exit 1)
	@magick identify -format '%[opaque]' android/app/src/main/res/drawable-mdpi/ic_stat_codewalk.png | grep -qi '^false$$' || (echo "Android notification icon must keep transparency"; exit 1)
	@test "$$(magick identify -format '%wx%h' web/icons/Icon-maskable-192.png)" = "192x192" || (echo "Invalid web maskable 192 icon"; exit 1)
	@test "$$(magick identify -format '%wx%h' web/icons/Icon-maskable-512.png)" = "512x512" || (echo "Invalid web maskable 512 icon"; exit 1)
	@grep -q '^\[Desktop Entry\]$$' linux/runner/resources/com.verseles.codewalk.desktop || (echo "Missing Desktop Entry header"; exit 1)
	@grep -q '^Type=Application$$' linux/runner/resources/com.verseles.codewalk.desktop || (echo "Desktop entry must be Type=Application"; exit 1)
	@grep -q '^Icon=com\.verseles\.codewalk$$' linux/runner/resources/com.verseles.codewalk.desktop || (echo "Desktop entry icon is not app-id based"; exit 1)
	@grep -q '^Exec=codewalk %U$$' linux/runner/resources/com.verseles.codewalk.desktop || (echo "Desktop entry Exec is unexpected"; exit 1)
	@grep -q '^StartupWMClass=com\.verseles\.codewalk$$' linux/runner/resources/com.verseles.codewalk.desktop || (echo "Desktop entry StartupWMClass mismatch"; exit 1)
	@grep -q 'android:inset="0%"' android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml || (echo "Adaptive icon inset is not 0%"; exit 1)
	@echo "Icon checks passed."

analyze:
	flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | tee $(ANALYZE_LOG) $(QUIET)
	bash tool/ci/check_analyze_budget.sh $(ANALYZE_LOG) 186

test:
	flutter test --no-pub $(QUIET)

test-parallel:
	flutter test --no-pub -j $(TEST_JOBS) $(QUIET)

test-fast:
	flutter test --no-pub -j $(TEST_JOBS) --exclude-tags "$(FAST_EXCLUDE_TAGS)" $(QUIET)

test-unit:
	flutter test --no-pub -j $(TEST_JOBS) test/unit test/presentation $(QUIET)

test-widget:
	flutter test --no-pub -j $(TEST_JOBS) test/widget test/widget_test.dart $(QUIET)

test-integration:
	flutter test --no-pub -j 1 --tags integration test/integration $(QUIET)

test-shard:
	@if [ -z "$(SHARD_TOTAL)" ] || [ -z "$(SHARD_INDEX)" ]; then \
		echo "Usage: make test-shard SHARD_TOTAL=<n> SHARD_INDEX=<i>"; \
		exit 1; \
	fi
	flutter test --no-pub -j $(TEST_JOBS) --total-shards $(SHARD_TOTAL) --shard-index $(SHARD_INDEX) $(QUIET)

coverage:
	flutter test --no-pub --coverage -j $(TEST_JOBS) $(QUIET)
	bash tool/ci/check_coverage.sh coverage/lcov.info 35

smoke:
	bash tool/qa/smoke_test.sh

check: deps gen analyze test

check-fast: deps gen analyze test-fast

desktop:
	@set -e; \
	if [ "$$OS" = "Windows_NT" ]; then \
		echo "Detected Windows host. Building Windows desktop app..."; \
		flutter build windows; \
		echo "Desktop build ready: build/windows/x64/runner/Release/"; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		echo "Detected macOS host. Building macOS desktop app..."; \
		flutter build macos; \
		echo "Desktop build ready: build/macos/Build/Products/Release/"; \
	elif [ "$$(uname -s)" = "Linux" ]; then \
		echo "Detected Linux host. Building Linux desktop app..."; \
		flutter build linux; \
		echo "Desktop build ready: build/linux/x64/release/bundle/"; \
	else \
		echo "Unsupported host OS for make desktop."; \
		exit 1; \
	fi

android:
	@if [ ! -f "$(ANDROID_KEY_PROPERTIES)" ]; then \
		echo "Missing $(ANDROID_KEY_PROPERTIES). Refusing to build a debug-signed release APK."; \
		echo "Create $(ANDROID_KEY_PROPERTIES) with keyAlias/keyPassword/storePassword/storeFile before running make android."; \
		exit 1; \
	fi
	@store_file=$$(awk '/^[[:space:]]*storeFile[[:space:]]*=/{sub(/^[^=]*=/,""); gsub(/\r/, ""); gsub(/^[[:space:]]+|[[:space:]]+$$/, ""); print; exit}' "$(ANDROID_KEY_PROPERTIES)"); \
	store_password=$$(awk '/^[[:space:]]*storePassword[[:space:]]*=/{sub(/^[^=]*=/,""); gsub(/\r/, ""); gsub(/^[[:space:]]+|[[:space:]]+$$/, ""); print; exit}' "$(ANDROID_KEY_PROPERTIES)"); \
	key_password=$$(awk '/^[[:space:]]*keyPassword[[:space:]]*=/{sub(/^[^=]*=/,""); gsub(/\r/, ""); gsub(/^[[:space:]]+|[[:space:]]+$$/, ""); print; exit}' "$(ANDROID_KEY_PROPERTIES)"); \
	key_alias=$$(awk '/^[[:space:]]*keyAlias[[:space:]]*=/{sub(/^[^=]*=/,""); gsub(/\r/, ""); gsub(/^[[:space:]]+|[[:space:]]+$$/, ""); print; exit}' "$(ANDROID_KEY_PROPERTIES)"); \
	if [ -z "$$store_file" ] || [ -z "$$store_password" ] || [ -z "$$key_password" ] || [ -z "$$key_alias" ]; then \
		echo "Incomplete $(ANDROID_KEY_PROPERTIES). Required keys: storeFile, storePassword, keyPassword, keyAlias."; \
		exit 1; \
	fi; \
	if [ ! -f "$$store_file" ] && [ ! -f "android/$$store_file" ] && [ ! -f "android/app/$$store_file" ]; then \
		echo "Keystore declared in $(ANDROID_KEY_PROPERTIES) not found: $$store_file"; \
		echo "Expected one of: $$store_file, android/$$store_file, android/app/$$store_file"; \
		exit 1; \
	fi
	flutter build apk --release --target-platform android-arm64 --split-per-abi $(QUIET)
	@if [ -f "$(APK_DIR)/app-arm64-v8a-release.apk" ]; then \
		mv -f "$(APK_DIR)/app-arm64-v8a-release.apk" "$(APK_PATH)"; \
		echo "APK ready (arm64-only): $(APK_PATH)"; \
	elif [ -f "$(APK_DIR)/app-release.apk" ]; then \
		mv -f "$(APK_DIR)/app-release.apk" "$(APK_PATH)"; \
		echo "APK ready (arm64-only): $(APK_PATH)"; \
	else \
		echo "APK output not found (expected arm64 build in $(APK_DIR))"; \
		exit 1; \
	fi
	@CAPTION_TEXT="$${HEY_CAPTION:-$$(git log -1 --pretty=%s 2>/dev/null || echo CodeWalk-Android-build)}"; \
	HEY_SYNC=1 ~/bin/hey -f "$(APK_PATH)" "$$CAPTION_TEXT"

precommit: check icons-check android

release:
	@if [ -z "$(V)" ]; then echo "Usage: make release V=patch|minor|major"; exit 1; fi
	@# Parse current version from pubspec.yaml
	$(eval CUR_VER := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//'))
	$(eval CUR_BUILD := $(shell grep '^version:' pubspec.yaml | sed 's/.*+//'))
	$(eval MAJOR := $(shell echo $(CUR_VER) | cut -d. -f1))
	$(eval MINOR := $(shell echo $(CUR_VER) | cut -d. -f2))
	$(eval PATCH := $(shell echo $(CUR_VER) | cut -d. -f3))
	$(eval NEW_BUILD := $(shell echo $$(($(CUR_BUILD) + 1))))
	@# Calculate new version
	$(eval NEW_VER := $(if $(filter major,$(V)),$(shell echo $$(($(MAJOR) + 1))).0.0,\
		$(if $(filter minor,$(V)),$(MAJOR).$(shell echo $$(($(MINOR) + 1))).0,\
		$(if $(filter patch,$(V)),$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH) + 1))),\
		$(error V must be patch, minor, or major)))))
	@echo "$(CUR_VER)+$(CUR_BUILD) -> $(NEW_VER)+$(NEW_BUILD)"
	@# Update pubspec.yaml
	@sed -i 's/^version: .*/version: $(NEW_VER)+$(NEW_BUILD)/' pubspec.yaml
	@# Commit, tag, push
	@git add pubspec.yaml
	@git commit -m "release: cut v$(NEW_VER)"
	@git tag -a "v$(NEW_VER)" -m "v$(NEW_VER)"
	@git push --follow-tags
	@echo "Released v$(NEW_VER) — CI and Release workflows triggered."

clean:
	flutter clean
	flutter pub get
