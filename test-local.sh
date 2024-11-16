#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Exit on any error
set -e

# VM configuration
VM_NAME="the-setup-test"
VM_CPU="2"
VM_MEM="4G"
VM_DISK="20G"
UBUNTU_VERSION="22.04"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print errors
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Check if Multipass is installed
print_header "Checking prerequisites"
if ! command -v multipass &> /dev/null; then
    print_error "Multipass is not installed"
    echo "Please install it first:"
    echo "brew install --cask multipass"
    exit 1
fi
print_success "Multipass is installed"

# Check if cloud-init.yaml exists and is valid
if [ ! -f build/cloud-init.yaml ]; then
    print_error "cloud-init.yaml not found in build directory"
    echo "Please run ./build.sh first"
    exit 1
fi

# Validate cloud-init.yaml format
export PYTHONPATH="$HOME/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"
if ! python3 -c "import yaml; yaml.safe_load(open('build/cloud-init.yaml'))" 2>/dev/null; then
    print_error "cloud-init.yaml is not valid YAML"
    echo "Please check the file for syntax errors"
    exit 1
fi
print_success "cloud-init.yaml is valid"

print_header "VM Management"
# Check if VM already exists
if multipass info ${VM_NAME} &> /dev/null; then
    print_warning "Test VM already exists"
    echo "Would you like to:"
    echo "1. Delete and recreate it"
    echo "2. Stop it"
    echo "3. Start it"
    echo "4. View cloud-init logs"
    echo "5. Exit"
    read -p "Choose an option (1-5): " choice
    
    case $choice in
        1)
            print_header "Recreating VM"
            echo "Deleting existing VM..."
            multipass delete ${VM_NAME} --purge
            ;;
        2)
            print_header "Stopping VM"
            multipass stop ${VM_NAME}
            print_success "VM stopped"
            exit 0
            ;;
        3)
            print_header "Starting VM"
            multipass start ${VM_NAME}
            print_success "VM started"
            exit 0
            ;;
        4)
            print_header "Cloud-Init Logs"
            multipass exec ${VM_NAME} -- sudo cat /var/log/cloud-init-output.log
            exit 0
            ;;
        *)
            echo "Exiting..."
            exit 0
            ;;
    esac
fi

print_header "Creating new VM"
echo "This will create a new Ubuntu ${UBUNTU_VERSION} VM with your cloud-init configuration"
echo "CPU: ${VM_CPU}"
echo "Memory: ${VM_MEM}"
echo "Disk: ${VM_DISK}"
echo

# Launch the VM with cloud-init
echo "Launching VM..."
multipass launch --name ${VM_NAME} \
    --cpus ${VM_CPU} \
    --memory ${VM_MEM} \
    --disk ${VM_DISK} \
    --cloud-init build/cloud-init.yaml \
    ${UBUNTU_VERSION}

print_success "VM created successfully"

print_header "Next Steps"
echo "To access the VM:"
echo "  multipass shell ${VM_NAME}"
echo
echo "To check VM status:"
echo "  multipass info ${VM_NAME}"
echo
echo "To view cloud-init logs:"
echo "  multipass exec ${VM_NAME} -- sudo cat /var/log/cloud-init-output.log"
echo
echo "To delete the VM when done:"
echo "  multipass delete ${VM_NAME} --purge"
echo
print_warning "Note: The first boot may take a few minutes while cloud-init configures the system"
