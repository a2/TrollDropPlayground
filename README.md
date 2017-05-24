# TrollDropPlayground

Send trollfaces via AirDrop to nearby devices... from an Xcode playground or an iPad running the [Swift Playgrounds](https://developer.apple.com/swift/playgrounds/) app.

## Usage

### Build Playgrounds

The _.playground_ files can be built with one of the following _rake_ commands:

```sh
# Build iPad and Xcode
rake build

# Build Xcode only
rake xcode:build

# Build iPad only
rake ipad:build
```

### Xcode

1. Open the built _Xcode.playground_ in Xcode.
2. Press the "Execute Playground" (play) button in the bottom toolbar, or select _Execute Playground_ from the _Editor_ menu.

#### Syncing Changes

After building the _Xcode.playground_ file and opening it in Xcode, you may have made changes. In order to easily re-integrate those into the main repo, you will want to run the following command:

```sh
rake xcode:sync
```

### iPad

1. Send the build _iPad.playground_ to an iPad supporting the Swift Playgrounds app (any 64-bit iPad). (You could even send the playground via AirDrop :thinking:?)
2. Tap the "Run My Code" button.

## Author

Alexsander Akers, me@a2.io

[Original implementation](https://github.com/neonichu/trolldrop) in collaboration with [Boris Bügling](https://github.com/neonichu).

## License

TrollDropPlayground is available under the MIT license. See the LICENSE file for more info.
