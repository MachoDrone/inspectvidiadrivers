#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'  # Green for checkmarks (✓) and their lines
RED='\033[0;31m'    # Red for crosses (✗) and their lines
NC='\033[0m'        # No Color (reset to default)

echo "=== NVIDIA Driver Setup Check (Basic Checks) ==="
echo "----------------------------------------"

# 1. Check if graphics-drivers PPA is configured (key for NVIDIA updates)
if grep -r "graphics-drivers/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/ >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Graphics-drivers PPA is configured (good for NVIDIA updates).${NC}"
else
    echo -e "${RED}✗ Graphics-drivers PPA is NOT configured. Updates may be limited.${NC}"
fi

# 2. Check available NVIDIA drivers (look for 560, suppress warnings)
echo -n "Available NVIDIA drivers: "
ubuntu-drivers list 2>/dev/null | grep "nvidia-driver" | head -n 3 | cut -d',' -f1 | tr '\n' ', ' | sed 's/, $//'
echo
if echo "$(ubuntu-drivers list 2>/dev/null)" | grep -q "nvidia-driver-560"; then
    echo -e "${GREEN}✓ Driver 560 is available for installation (if needed).${NC}"
else
    echo -e "${RED}✗ Driver 560 is NOT available. Repositories may need updating.${NC}"
fi

# 3. Check currently installed NVIDIA driver
if command -v nvidia-smi >/dev/null 2>&1; then
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1)
    echo -e "${GREEN}✓ Current NVIDIA driver version: $DRIVER_VERSION${NC}"
    if [[ "$DRIVER_VERSION" == "560."* ]]; then
        echo -e "${GREEN}✓ You are using driver 560 (optimal for Nosana).${NC}"
    else
        echo -e "${RED}✗ You are NOT using driver 560. Current version: $DRIVER_VERSION${NC}"
    fi
else
    echo -e "${RED}✗ nvidia-smi not found. NVIDIA driver may not be installed.${NC}"
fi

# 4. Check Secure Boot status
if command -v mokutil >/dev/null 2>&1; then
    if mokutil --sb-state 2>/dev/null | grep -q "disabled"; then
        echo -e "${GREEN}✓ Secure Boot is disabled (good for proprietary drivers).${NC}"
    else
        echo -e "${RED}✗ Secure Boot is enabled. May block proprietary drivers. Check BIOS.${NC}"
    fi
else
    echo -e "${RED}✗ mokutil not installed. Check BIOS or logs for Secure Boot status.${NC}"
    if grep -i "secure boot" /var/log/syslog /var/log/boot.log 2>/dev/null | grep -q "disabled"; then
        echo "  (Logs suggest Secure Boot is disabled.)"
    fi
fi

# 5. Check last reboot time (simplified)
if command -v last >/dev/null 2>&1; then
    LAST_REBOOT=$(last -x | grep reboot | head -n 1 | awk '{print $5, $6, $7}')
    echo -e "${GREEN}✓ Last reboot: $LAST_REBOOT${NC}"
else
    echo -e "${RED}✗ 'last' command not found. Cannot check reboot history.${NC}"
fi

# 6. Check PRIME settings (NVIDIA GPU usage)
if command -v prime-select >/dev/null 2>&1; then
    PRIME_SETTING=$(prime-select query 2>/dev/null)
    if [ "$PRIME_SETTING" = "nvidia" ] || [ "$PRIME_SETTING" = "on-demand" ]; then
        echo -e "${GREEN}✓ PRIME is set to '$PRIME_SETTING' (NVIDIA GPU is used).${NC}"
    else
        echo -e "${RED}✗ PRIME is set to '$PRIME_SETTING'. May not use NVIDIA GPU.${NC}"
    fi
else
    echo -e "${RED}✗ prime-select not installed. Check nvidia-smi for GPU use.${NC}"
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "  (nvidia-smi confirms NVIDIA GPU is detected.)"
    fi
fi

echo "----------------------------------------"
echo "Note: This check is read-only and doesn’t change your system."
