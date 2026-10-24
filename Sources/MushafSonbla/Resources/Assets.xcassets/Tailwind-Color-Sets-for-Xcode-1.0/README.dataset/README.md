# Tailwind Color Sets for Xcode

<p>
    <img src="https://img.shields.io/badge/Swift-3+-orange" />
    <img src="https://img.shields.io/badge/Xcode-9+-orange" />
    <img src="https://img.shields.io/badge/Platform-iOS_11%2B_%7C_iPadOS_13%2B_%7C_macOS_10.13%2B_%7C_tvOS%2011%2B_%7C_visionOS_1%2B_%7C_watchOS_4%2B-orange" />
</p>

Tailwind Color Sets is an Xcode Assets library containing the entire [Tailwind CSS](https://tailwindcss.com/) color palette.

Adding this library to the Assets folder in your Swift project enables instant availability of all Tailwind colors.

## Color palette

- `Color.twAmber`
- `Color.twBlue`
- `Color.twCyan`
- `Color.twEmerald`
- `Color.twFuchsia`
- `Color.twGray`
- `Color.twGreen`
- `Color.twIndigo`
- `Color.twLime`
- `Color.twNeutral`
- `Color.twOrange`
- `Color.twPink`
- `Color.twPurple`
- `Color.twRed`
- `Color.twRose`
- `Color.twSky`
- `Color.twSlate`
- `Color.twStone`
- `Color.twTeal`
- `Color.twViolet`
- `Color.twYellow`
- `Color.twZinc`

Each color is available in 11 tints, e.g. `Color.twBlue50`, `Color.twBlue100` ... `Color.twBlue900`, `Color.twBlue950`.

## Installation

1. Prepare your Xcode project:
    1. Open your project in Xcode
    1. Select Assets in the Project Navigator
1. Download the Tailwind Color Sets library:
    1. Download the latest release from [the Releases page](https://github.com/leomakkinje/Tailwind-Color-Sets-for-Xcode/releases) or by clicking [this link](https://github.com/leomakkinje/Tailwind-Color-Sets-for-Xcode/archive/refs/tags/1.0.0.zip)
    1. Open the Downloads folder on your computer
    1. Double-click file `Tailwind-Color-Sets-for-Xcode-1.0.0.zip` to unzip it
    1. Double-click folder `Tailwind-Color-Sets-for-Xcode-1.0.0` to open it
1. Add the Tailwind Color Sets library to your Xcode project:
    1. Drag folder `Tailwind Color Sets` into the `Assets` column in Xcode

## Usage

Tailwind colors are used the same way you would use any other color in Swift. Simply refer to the color's name, e.g. `Color.twBlue` or `.twBlue`.

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Little Green Bag")
                .foregroundStyle(.twGreen)
            Text("Red Right Hand")
                .foregroundStyle(.twRed)
        }
        .background(.twYellow200)
    }
}
```

## License

This project is open source and available under the MIT license. For more information, see the [LICENSE](https://github.com/leomakkinje/Tailwind-Color-Sets-for-Xcode/blob/main/LICENSE) file.

## Disclaimer

This project is not affiliated with, sponsored by, or endorsed by [Tailwind CSS](https://tailwindcss.com/).
