# Copyright 2023 defsub
#
# This file is part of Cabrillo.
#
# Cabrillo is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# Cabrillo is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Cabrillo.  If not, see <https://www.gnu.org/licenses/>.

FLUTTER = flutter

DART = dart

ADB = adb

GIT_VERSION ?= $(shell git log --format="%h" -n 1)

SOURCES = $(wildcard lib/*.dart lib/*/*.dart)

TARGET_PLATFORM = android-arm64,android-arm

RELEASE_APK = ./build/app/outputs/flutter-apk/app-release.apk

DEBUG_APK = ./build/app/outputs/flutter-apk/app-debug.apk

.PHONY: build

all: apk

release: clean update generate release

apk: ${RELEASE_APK}

install: apk
	${ADB} install ${RELEASE_APK}

install-debug: debug
	${ADB} install ${DEBUG_APK}

update:
	${FLUTTER} pub get

analyze:
	${FLUTTER} analyze

generate:
	${DART} run build_runner build --delete-conflicting-outputs

release: ${RELEASE_APK}

${RELEASE_APK}: ${SOURCES}
	${FLUTTER} build apk --release --target-platform ${TARGET_PLATFORM}

debug: ${DEBUG_APK}

${DEBUG_APK}: ${SOURCES}
	${FLUTTER} build apk --debug --target-platform ${TARGET_PLATFORM}

bundle: release
	${FLUTTER} build appbundle

clean:
	${FLUTTER} clean

version:
	scripts/version.sh
