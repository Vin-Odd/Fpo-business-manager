#!/usr/bin/env bash
# Run this from inside the extracted zip folder (same folder as
# pubspec.yaml). Requires Flutter already installed (`flutter doctor`
# should work before running this).
set -e

PROJECT_NAME="fpo_business_manager"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$PROJECT_NAME" ]; then
  echo "A '$PROJECT_NAME' folder already exists here — remove or rename it first."
  exit 1
fi

echo "==> Creating Flutter project (adds android/ios/etc. platform folders)..."
flutter create "$PROJECT_NAME"

echo "==> Copying pubspec.yaml, analysis_options.yaml, and lib/ in..."
cp "$SOURCE_DIR/pubspec.yaml" "$PROJECT_NAME/pubspec.yaml"
cp "$SOURCE_DIR/analysis_options.yaml" "$PROJECT_NAME/analysis_options.yaml"
rm -rf "$PROJECT_NAME/lib"
cp -r "$SOURCE_DIR/lib" "$PROJECT_NAME/lib"

cd "$PROJECT_NAME"

echo "==> Fetching packages (flutter pub get)..."
flutter pub get

echo "==> Generating drift/riverpod code (build_runner)..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "Done. Connect a device or emulator, then:"
echo "  cd $PROJECT_NAME && flutter run"
