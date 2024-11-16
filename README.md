# Supreme Computing Machine 🚀

A comprehensive cloud infrastructure deployment system for self-hosting multiple services with automated backups, security features, and seamless integration.

## Features ✨

- 🔐 **Secure by Default**: Automated SSL/TLS setup with Let's Encrypt
- 🔄 **Automated Backups**: Built-in backup system with configurable schedules
- 🤖 **Telegram Notifications**: Get alerts about system events
- 🛠 **Easy Setup**: Interactive configuration with sensible defaults
- 🏗 **Modular Design**: Easy to extend and customize
- 🔒 **Security First**: Automated firewall setup and secure credential generation

## Included Services 🌟

- **PostgreSQL**: Robust relational database
- **Appwrite**: Backend as a Service platform
- **Baserow**: Open source no-code database tool
- **Qdrant**: Vector similarity search engine
- **Minio**: S3-compatible object storage
- **Redis**: In-memory data structure store
- **Keycloak**: Identity and access management

## Quick Start 🚀

1. Clone the repository:
   ```bash
   git clone https://github.com/PetrBrabec/supreme-computing-machine.git
   cd supreme-computing-machine
   ```

2. Run the setup script:
   ```bash
   # Interactive mode
   ./setup.sh
   
   # Or use defaults
   ./setup.sh -y
   ```

3. Test your configuration:
   ```bash
   ./test.sh
   ```

4. Build cloud-init configuration:
   ```bash
   ./build.sh
   ```
   This will generate a `cloud-init.yaml` file in the `build` directory with your configuration.

5. Test locally (optional):
   ```bash
   ./test-local.sh
   ```
   This uses Multipass to test your cloud-init configuration in a local VM.

## Requirements 📋

- Linux/macOS system
- Docker and Docker Compose
- bash
- openssl
- curl (for testing)
- Multipass (for local testing)

## Configuration 🛠

The setup script will guide you through configuring:

- Domain and SSL certificate settings
- Database credentials
- Service-specific configurations
- Backup settings
- Notification preferences

All configuration is stored in a `.env` file, which you can edit manually if needed.

## Build Process 🏗

The build process consists of several steps:

1. **Environment Setup**: Configure your environment using `setup.sh`
   - Interactive prompts for configuration
   - Secure credential generation
   - Environment file creation

2. **Cloud-Init Generation**: Generate deployment configuration using `build.sh`
   - Converts environment variables to cloud-init format
   - Includes all necessary scripts and configurations
   - Creates a ready-to-use cloud-init.yaml file

3. **Local Testing**: Test your configuration using `test-local.sh`
   - Creates a local VM using Multipass
   - Deploys your configuration
   - Verifies service setup and connectivity

4. **Deployment**: Use the generated `cloud-init.yaml` with your cloud provider
   - Compatible with any cloud provider supporting cloud-init
   - Automatic service setup and configuration
   - Secure credential handling

## Security 🔒

- Automatic firewall configuration
- Secure password generation
- SSL/TLS encryption
- Regular security updates
- Protected service endpoints

## Backup System 💾

- Automated daily backups
- Configurable retention policy
- Off-site backup support
- Backup status notifications
- Easy restore process

## Monitoring 📊

- Telegram notifications for:
  - Backup status
  - Service health
  - System updates
  - Security events

## Development 🔧

Want to contribute? Great! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

## Support 💬

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/PetrBrabec/supreme-computing-machine/issues) page
2. Create a new issue if needed
3. Provide as much detail as possible

## Acknowledgments 🙏

- All the amazing open source projects that make this possible
- The community for their valuable feedback and contributions

---

Made with ❤️ by [Petr Brabec](https://github.com/PetrBrabec)
