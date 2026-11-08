# Tiny Ritual

[Play in your browser](https://maxbouchez.github.io/tiny-ritual/) |
[Download a release](https://github.com/maxbouchez/tiny-ritual/releases) |
[Build status](https://github.com/maxbouchez/tiny-ritual/actions)

A personal game collection starter for **Android, iPhone/iPad, Windows, and browsers**.
Built with **Godot 4.7.2 standard edition**, GDScript, and the Compatibility renderer.
The engine version is pinned in [.godot-version](.godot-version).

This is a fresh project inspired by the multi-platform approach of Sweet Vinegar
Games, not a copy of that repository. The initial scene is an input check, not a
finished game: the target increments a counter and Reset clears it.

## Start on Windows

Run these commands from the repository folder in PowerShell:

```powershell
./tools/setup.ps1
./tools/godot.ps1 -Action Editor
```

The setup script downloads the official standard Windows x64 editor, checks its
SHA-256 against GitHub release metadata, and extracts it into the ignored
`.tools` directory. It does not need administrator access or change your PATH.
On Windows ARM64 it uses x64 emulation; install the native editor manually and
set `GODOT_BIN` if preferred.

In Godot, press **F6** to run an open scene or **F5** to run the project. You can
also run the starter or its tests directly:

```powershell
./tools/godot.ps1 -Action Run
./tools/godot.ps1 -Action Test
```

In VS Code, install the recommended **Godot Tools** extension and use
**Terminal > Run Task > Godot: Open Editor / Run / Test / Export**. Keep the
project open in Godot for the extension's language server. Godot's editor is
used for scenes and visual layout; VS Code and Copilot can be used for scripts.

The tasks work with Windows PowerShell; macOS/Linux tasks require PowerShell 7
and `GODOT_BIN` set to the absolute path of the matching Godot executable.
Alternatively, open [project.godot](project.godot) directly in Godot on any OS.
No Python, Node.js, .NET SDK, backend, or database is required.

## Export prerequisites

All platforms require export templates matching **4.7.2**. On Windows:

```powershell
./tools/setup.ps1 -Templates
```

This downloads approximately **1.3 GB** and installs all platform templates into
your user-level Godot data directory. On other systems, use **Editor > Manage
Export Templates**. The download cache remains in `.tools/downloads` and can be
deleted to reclaim space after setup.

| Target | Additional requirements | Output |
| --- | --- | --- |
| Windows | None for the unsigned development build | `build/windows/TinyRitual.exe` |
| Browser | WebGL 2-capable browser; HTTP localhost or HTTPS hosting | `build/web/index.html` plus companion files |
| Android | OpenJDK 17, Android SDK, debug signing setup | `build/android/TinyRitual.apk` |
| iOS | macOS, Xcode, Apple account/team and device signing | `build/ios/TinyRitual.zip` containing an Xcode project |

Build outputs are ignored by Git. The helper creates their directories and
prevents Godot from importing exported files back into the project.

### Windows

```powershell
./tools/godot.ps1 -Action Export -Target Windows
```

The x64 build embeds its resource pack. Code signing and Windows executable
resource modification are disabled, so no signing certificate or resource
editing utility is needed. Windows may warn about an unsigned downloaded app.

### Browser, including Android and iPhone browsers

```powershell
./tools/godot.ps1 -Action Export -Target Web
./tools/serve-web.ps1
```

Open **http://localhost:8060/**. If the port is occupied, use
`./tools/serve-web.ps1 -Port 8061`. The preview server binds only to localhost
and serves only the generated web directory; it is not a production server.
If Windows denies permission to start the listener, use Godot's web preview
instead; do not run the editor or preview server as administrator.

Do not double-click the exported HTML: Godot needs HTTP/HTTPS to load WebAssembly.
For phone testing, upload the **entire** `build/web` directory to an HTTPS static
host, such as GitHub Pages or itch.io. `localhost` on a phone refers to the phone,
not your PC. Verify that `.wasm` is served as `application/wasm`.

The Web preset disables threads and GDExtensions, avoiding special cross-origin
isolation headers. PWA support is enabled for home-screen installation and
offline caching after a successful initial load, subject to browser support and
storage limits. Clear the site's service worker/cache if an old build persists.
Browser storage may be cleared or evicted; do not treat it as a guaranteed backup.
Test Safari and actual phones before relying on performance, audio, or touch behavior.

### Android

1. Install [OpenJDK 17](https://adoptium.net/temurin/releases/?version=17).
2. Install [Android Studio](https://developer.android.com/studio) and use its SDK
   Manager to install Platform-Tools, Build-Tools **35.0.1**, Android Platform
   **35**, Command-line Tools (latest), NDK **28.1.13356709**, and CMake
   **3.10.2.4988404**, following the [Godot 4.7 export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
3. In **Godot > Editor Settings > Export > Android**, set Java SDK Path and
   Android SDK Path. The SDK is usually under `%LOCALAPPDATA%\Android\Sdk`.
   Follow any debug-keystore setup prompt in Godot; do not commit signing keys.
4. The Android application ID is `io.github.maxbouchez.tinyritual`. Keep it
   stable so future builds can update the same installed game.
5. Enable Developer Options and USB debugging on your phone, connect it, and
   authorize the PC. Use Godot's device deploy button or export an APK:

```powershell
./tools/godot.ps1 -Action Export -Target Android
```

The default is a **debug-signed APK** for personal testing, supporting ARM64
phones and x64 emulators. No Play Store account is required for local development.
The starter requests no internet permission. The SDK warning during other exports
is expected until Android tools are configured.

Store publication is separate: configure release signing, increment the version
code, and use an AAB/Gradle export for Google Play. The `-Release` switch alone
does not set up signing or switch this APK preset to AAB.

### iPhone/iPad native app

Windows can edit and test the shared game, but **native iOS export/build/signing
requires a Mac with Xcode**. An iPhone browser build does not require a Mac.

1. On a Mac, install the pinned Godot standard editor, matching templates, Xcode,
   and its platform components. Open Xcode once to complete setup.
2. Open this project in Godot. Under **Project > Export > iOS**, enter your Apple
   Team ID and register the bundle identifier `io.github.maxbouchez.tinyritual`.
3. Export with **Export Project Only** enabled to a new directory under
   `build/ios`. The included preset uses a ZIP containing the Xcode project.
4. Extract it, open the generated project in Xcode, select your signing team and
   connected iPhone, enable Developer Mode if prompted, and build/run.

A free Apple account allows limited personal-device testing with periodic
re-signing. TestFlight/App Store distribution requires paid membership and
additional signing/release setup. See the [Godot iOS guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html).
Do not put certificates, provisioning profiles, or passwords into Git.

## Project layout

- [scenes/main.tscn](scenes/main.tscn): starter scene using responsive containers.
- [scripts/main.gd](scripts/main.gd): shared touch/mouse button behavior.
- [assets](assets): game artwork and audio; currently an original SVG icon.
- [tests/smoke.gd](tests/smoke.gd): preset, scene-loading, input, and reset checks.
- [export_presets.cfg](export_presets.cfg): all four platform configurations.
- [tools](tools): portable setup, test/export commands, and local web preview.
- [.github/workflows/build.yml](.github/workflows/build.yml): tests, Windows/browser
   build artifacts, GitHub Pages deployment, and tagged releases.

## CI/CD and releases

- Pull requests: import, test, and export Windows/browser builds. No deployment
   or release permissions are granted to the build job.
- Pushes to `main`: run the same checks, then deploy the browser build to
   **https://maxbouchez.github.io/tiny-ritual/** using GitHub Pages.
- Tags starting with `v`: build and publish a GitHub Release containing Windows
   x64 and browser ZIPs plus SHA-256 checksums. The tag must match the app version.
- Manual workflow runs: rebuild the selected ref; selecting `main` also redeploys
   the site. Downloadable workflow artifacts are retained for seven days.

For Windows, download the Windows ZIP from Releases, extract it, and launch
`TinyRitual.exe`. No installer is needed. The executable is unsigned, so Windows
may show a warning. Keep the included engine license notices with the build.
For phones, open the HTTPS browser build and use the browser's home-screen
installation option where supported. Native Android/iOS release packages are
not configured yet; their SDK/signing requirements above still apply.

To publish a new version, update `config/version` in [project.godot](project.godot)
and the native version fields in [export_presets.cfg](export_presets.cfg), commit,
and push `main`. Then tag that commit with the matching version, for example:

```shell
git tag v0.1.1
git push origin v0.1.1
```

The example assumes the app version has first been changed to `0.1.1`.
Do not move published tags or reuse version numbers. The release step refuses
to replace an existing release. The Pages site always follows `main`, while
release ZIPs remain tied to their tagged source. A fork must enable Pages with
**GitHub Actions** as its source and adjust the URLs in this file and workflow.

CI does not publish to app stores. Standard hosted Actions runners are free for
public repositories; GitHub service limits and artifact retention still apply.

## Add your first game

Create a scene under `scenes/` and its GDScript under `scripts/`, then select it
as the main scene in Project Settings or connect it to a game-selection scene.
Update the smoke test when replacing the input-check screen. Use Godot's built-in
input, UI, animation, and physics APIs rather than platform-specific code.

Keep Compatibility rendering and GDScript for browser portability. The starter
uses a 480 x 800 design size, canvas-item stretching, portrait mobile orientation,
and mouse emulation from touch. Check real-device safe areas, screen sizes,
pause/resume, and saves as games grow. Use `user://` for future save files rather
than writing to the packaged `res://` directory.

This starter has no analytics, accounts, cloud saves, or multiplayer. Add those
only when a game needs them. Save, sound, and haptic behavior are not implemented.

## GitHub and licensing

The public repository is **https://github.com/maxbouchez/tiny-ritual**. Generated
files and common signing secrets are ignored. Never commit credentials or
signing keys, even temporarily: public Git history can be copied immediately.

No license for your own code has been chosen for you; public visibility alone
does not grant a general reuse license. CI bundles Godot's license and third-party
copyright notices with the Windows/browser builds. Include licenses/attributions
for any fonts, art, sound, or plugins you add. Sweet Vinegar Games is an
architectural reference only; none of its project code or artwork is included.