# Caddy UI

A modern, cross-platform GUI application for managing Caddy web server configurations. Built with Flutter, this application provides an intuitive interface for managing your Caddy server without dealing directly with JSON configurations.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-%5E3.5.3-blue.svg)
![Platform](https://img.shields.io/badge/platform-android%20|%20ios%20|%20linux%20|%20macos%20|%20windows-lightgrey.svg)
![Build Status](https://github.com/makinghappen/caddy-ui/actions/workflows/build.yml/badge.svg)

## Features

- 🌲 **Tree-based Config Editor**: Visualize and edit your Caddy configuration in a hierarchical tree view
- 🔍 **Smart Search**: Quickly find and navigate to specific configuration sections
- 🔄 **Live Configuration**: Apply changes to your running Caddy server without restart
- 📊 **Server Status Monitoring**: Real-time monitoring of your Caddy server status
- 🔐 **PKI Certificate Management**: Manage SSL/TLS certificates directly from the UI
- 🔄 **Reverse Proxy Management**: Configure and monitor reverse proxy upstreams
- 💾 **Config Import/Export**: Easily backup and restore your Caddy configurations
- 🌐 **Cross-Platform**: Runs on Android, iOS, Linux, macOS, and Windows


## Demo

Try out Caddy UI directly in your browser at [https://makinghappen.github.io/caddy-ui](https://makinghappen.github.io/caddy-ui)

## Installation

### Prebuilt Binaries

Download the latest release for your platform from the [Releases](https://github.com/makinghappen/caddy-ui/releases) page.

### Prerequisites

- Flutter SDK ≥3.5.3
- Dart SDK ≥3.0.0
- Caddy Server ≥2.0.0

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/makinghappen/caddy-ui.git
cd caddy-ui
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Running Caddy in Docker

### Basic Setup

1. Create a Caddyfile:
```bash
mkdir caddy-data
echo "localhost:80 {
    respond \"Hello, World!\"
}" > Caddyfile
```

2. Run Caddy with Docker:
```bash
docker run -d \
    --name caddy \
    -p 80:80 \
    -p 443:443 \
    -p 2019:2019 \
    -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
    -v caddy_data:/data \
    -v caddy_config:/config \
    caddy:2-alpine
```

### Docker Compose Setup

Create a `docker-compose.yml`:

```yaml
version: '3.7'
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
      - "2019:2019"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
```

Run with:
```bash
docker-compose up -d
```

## Usage

1. Start your Caddy server (either locally or in Docker)
2. Launch Caddy UI
3. Connect to your Caddy server's API endpoint (default: http://localhost:2019)
4. Start managing your Caddy configuration through the intuitive interface

### Key Operations

- **View Configuration**: Use the tree view to navigate through your Caddy config
- **Edit Configuration**: Click on any node to modify its values
- **Search**: Use the search bar to find specific configuration elements
- **Apply Changes**: Changes are automatically applied to your running Caddy server
- **Monitor Status**: View server status and running configuration in real-time

## Development

### CI/CD Pipeline

The project uses GitHub Actions for continuous integration and deployment:

- **Automated Testing**: Every push and pull request triggers automated tests
- **Web Deployment**: Changes to main branch are automatically deployed to GitHub Pages
- **Release Builds**: Creating a new release automatically builds and uploads binaries for:
  - Linux (.tar.gz)
  - Windows (.zip)
  - macOS (.zip)

### Project Structure

```
lib/
├── src/
│   ├── models/         # Data models
│   ├── services/       # Business logic and API services
│   └── ui/            # UI components and pages
│       └── config_editor/  # Configuration editor components
```

### Running Tests

```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Caddy Server](https://caddyserver.com/) for the amazing web server
- [Flutter](https://flutter.dev/) for the cross-platform framework
