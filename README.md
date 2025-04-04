<div align="center">
  
# 🚀 Backhaul Easy

A powerful and user-friendly CLI tool for managing backhaul configurations with ease.

[![GitHub license](https://img.shields.io/github/license/masihjahangiri/backhaul-easy)](https://github.com/masihjahangiri/backhaul-easy/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/masihjahangiri/backhaul-easy)](https://github.com/masihjahangiri/backhaul-easy/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/masihjahangiri/backhaul-easy)](https://github.com/masihjahangiri/backhaul-easy/issues)

</div>

## 🌟 Features

- 📱 Interactive menu-driven interface
- 🔧 System & Network optimizations
- 🔄 Automatic tunnel management
- 🛠️ Easy configuration for both Iran and Kharej servers
- 🔄 One-command installation and updates
- 💻 Cross-platform support (amd64/arm64)

## 🚀 Quick Start

### One-Line Installation

```bash
bash <(curl -Ls https://raw.githubusercontent.com/masihjahangiri/backhaul-easy/main/script.sh)
```

After installation, you can run the tool using:

```bash
bh
```

## 📺 CLI Menu Preview

When you run the tool, you'll be greeted with this interactive menu:

```ascii
██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     
██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     
██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     
██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     
██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗
╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
███████╗ █████╗ ███████╗██╗   ██╗
██╔════╝██╔══██╗██╔════╝╚██╗ ██╔╝
█████╗  ███████║███████╗ ╚████╔╝ 
██╔══╝  ██╔══██║╚════██║  ╚██╔╝  
███████╗██║  ██║███████║   ██║   
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   

Select an option:
1) System & Network Optimizations
2) Install Backhaul and Setup Tunnel
3) Manage Backhaul Tunnels
4) Update Script from GitHub
0) Exit
Enter your choice:
```

## 🛠️ Main Features

1. **System & Network Optimizations**
   - Automatic sysctl optimizations
   - System limits configuration
   - Network performance tuning

2. **Backhaul Installation & Setup**
   - Easy tunnel configuration
   - Support for both Iran and Kharej servers
   - Automatic service management

3. **Tunnel Management**
   - Start/Stop tunnels
   - View logs and status
   - Edit configurations
   - Remove tunnels

4. **Auto-Updates**
   - One-click script updates
   - Automatic version checking

## 🔧 System Requirements

- Linux-based operating system
- Root access
- Active internet connection
- Supported architectures: amd64, arm64

## 📝 Configuration

The tool provides an interactive menu for all configurations. You'll need:

- Port numbers for tunnels
- Token for authentication
- Server IP addresses (for Kharej setup)
- Port forwarding rules (for Iran setup)

## 🔍 Troubleshooting

1. Check tunnel status:
   ```bash
   bh
   # Select option 3 (Manage Backhaul Tunnels)
   ```

2. View logs:
   - Select a tunnel from the management menu
   - Choose option 1 or 2 to view logs

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⭐ Support

If you find this tool helpful, please consider giving it a star on GitHub!

## 🔐 Security

- Always use strong tokens for tunnel authentication
- Keep your system and the script up to date
- Monitor logs regularly for any suspicious activity

---

Made with ❤️ by [Masih Jahangiri](https://github.com/masihjahangiri)
