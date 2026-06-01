.PHONY: android-dev android-prod android-aab ios-prod windows-prod macos-prod linux-prod

android-dev:
	node scripts/build.mjs android dev debug

android-prod:
	node scripts/build.mjs android prod release

android-aab:
	node scripts/build.mjs android:aab prod release

ios-prod:
	node scripts/build.mjs ios prod release

windows-prod:
	node scripts/build.mjs windows prod release

macos-prod:
	node scripts/build.mjs macos prod release

linux-prod:
	node scripts/build.mjs linux prod release
