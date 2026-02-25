# OrMiMu Project Setup

This project uses **XcodeGen** to automatically generate the `.xcodeproj` file from the source code structure. This ensures that:
1. Adding files to the `OrMiMu/` folder automatically adds them to the project.
2. Merge conflicts in `project.pbxproj` are eliminated.
3. Build settings are consistent across the team.

## Prerequisites

- macOS with Xcode installed.
- [Homebrew](https://brew.sh/) installed.

## Getting Started

1. Clone the repository.
2. Run the setup script:

```bash
./scripts/setup.sh
```

This will install `xcodegen` and `swiftlint` (if missing) and generate the `OrMiMu.xcodeproj` file.

## Workflow

### Adding New Files
1. Create your Swift file in the `OrMiMu/` directory (or subdirectories).
2. Run `xcodegen` in the terminal (at the project root).
3. Open/Reload the project in Xcode.

Alternatively, you can add files in Xcode as usual, but remember that the project file is generated. It's best practice to rely on the file system structure.

### Linting
The project includes **SwiftLint** to enforce code style. Warnings/Errors will appear in Xcode build results. To fix auto-fixable issues run:
```bash
swiftlint --fix
```

## Configuration
- Project settings are defined in `project.yml`.
- Linting rules are in `.swiftlint.yml`.
