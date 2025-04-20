# TWRA - Tactical WoW Raid Assistant

TWRA is an addon for World of Warcraft that helps raid leaders and participants manage and optimize raid encounters by providing tactical information and automated features.

## Features

- **Auto Navigation**: Automatically guides players to the correct positions during raid encounters
- **Auto Tanks**: Helps with tank swapping and positioning
- **Raid Data Synchronization**: Keeps tactical information in sync across raid members
- **Item Link Management**: Enhanced item management features
- **OSD (On-Screen Display)**: Visual indicators for important raid mechanics
- **Spreadsheet Integration**: Import/export raid data to Google Sheets

## Installation

1. Download the latest release from [GitHub](https://github.com/YOUR_USERNAME/TWRA)
2. Extract the zip file
3. Move the `TWRA` folder to your `Interface/AddOns` directory
4. Restart World of Warcraft or reload your UI (`/reload`)

## Usage

Basic usage information:

```
/twra help - Shows available commands
/twra show - Shows the main TWRA window
/twra hide - Hides the TWRA window
```

For detailed usage instructions, refer to the in-game help or visit our documentation.

## Spreadsheet Integration

TWRA integrates with Google Sheets for raid planning. The addon can import data from specially formatted Google Sheets to load raid strategies and positioning.

See the docs/scripts directory for JavaScript examples that can be used with Google Sheets.

## Development

### Project Structure

```
TWRA/
├── core/ - Core functionality and utilities
├── features/ - Specific features like AutoNavigate
├── libs/ - Third-party libraries
├── sync/ - Data synchronization between raid members
├── ui/ - User interface components
└── docs/ - Documentation and scripts
```

### Dependencies

- LibStub (included)
- LibCompress (included)

## License

This project is licensed under GNU General Public License v2.0 (GPL-2.0). See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Acknowledgments

- Thanks to the authors of LibCompress: jjsheets and Galmok of European Stormrage (Horde)
- LibStub authors: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke