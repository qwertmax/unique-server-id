# unique-server-id


```go
// getMAC returns the MAC address of the first non-loopback interface
func getMAC() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}

	for _, iface := range interfaces {
		// Skip loopback interface and interfaces without MAC
		if iface.Flags&net.FlagLoopback != 0 || iface.HardwareAddr == nil {
			continue
		}
		// Return first valid MAC address
		if hwAddr := iface.HardwareAddr.String(); hwAddr != "" {
			return hwAddr
		}
	}
	return ""
}

// getCPUInfo reads detailed CPU information
func getCPUInfo() string {
	// Try reading CPU ID using dmidecode (requires root)
	cmd := exec.Command("dmidecode", "-t", "processor")
	output, err := cmd.Output()
	if err == nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "ID:") || strings.Contains(line, "Serial Number:") {
				return strings.TrimSpace(line)
			}
		}
	}

	// Fallback: Read from /proc/cpuinfo
	content, err := os.ReadFile("/proc/cpuinfo")
	if err != nil {
		return ""
	}

	cpuInfo := make([]string, 0)
	lines := strings.Split(string(content), "\n")

	// Collect relevant CPU information
	for _, line := range lines {
		if strings.HasPrefix(line, "model name") ||
			strings.HasPrefix(line, "physical id") ||
			strings.HasPrefix(line, "serial") ||
			strings.HasPrefix(line, "core id") {
			cpuInfo = append(cpuInfo, strings.TrimSpace(line))
		}
	}

	return strings.Join(cpuInfo, "|")
}

// getHostname returns the system hostname
func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return ""
	}
	return hostname
}

// getDiskSerial attempts to get disk serial number using multiple methods
func getDiskSerial() string {
	// Method 1: Try hdparm (requires root)
	cmd := exec.Command("hdparm", "-I", "/dev/sda")
	output, err := cmd.Output()
	if err == nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "Serial Number:") {
				return strings.TrimSpace(strings.Split(line, ":")[1])
			}
		}
	}

	// Method 2: Try lsblk
	cmd = exec.Command("lsblk", "--nodeps", "-no", "serial", "/dev/sda")
	output, err = cmd.Output()
	if err == nil && len(output) > 0 {
		return strings.TrimSpace(string(output))
	}

	// Method 3: Try reading from /dev/disk/by-id
	files, err := os.ReadDir("/dev/disk/by-id")
	if err == nil {
		for _, file := range files {
			name := file.Name()
			// Look for ATA or SCSI disk identifiers
			if (strings.Contains(name, "ata") || strings.Contains(name, "scsi")) &&
				!strings.Contains(name, "part") {
				return name
			}
		}
	}

	// Method 4: Try udevadm (another alternative)
	cmd = exec.Command("udevadm", "info", "--query=all", "--name=/dev/vda1")
	output, err = cmd.Output()
	if err == nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "ID_SERIAL=") {
				return strings.TrimSpace(strings.Split(line, "=")[1])
			}
		}
	}

	return ""
}

// getMachineID gets the Linux machine-id
func getMachineID() string {
	// Try reading from /etc/machine-id first
	content, err := os.ReadFile("/etc/machine-id")
	if err == nil {
		return strings.TrimSpace(string(content))
	}

	// If /etc/machine-id doesn't exist, try /var/lib/dbus/machine-id
	content, err = os.ReadFile("/var/lib/dbus/machine-id")
	if err == nil {
		return strings.TrimSpace(string(content))
	}

	return ""
}

// getProductUUID gets the product UUID from /sys/class/dmi/id/product_uuid
func getProductUUID() string {
	content, err := os.ReadFile("/sys/class/dmi/id/product_uuid")
	if err == nil {
		return strings.TrimSpace(string(content))
	}
	return ""
}

// generateServerID combines various hardware identifiers to create a unique server ID
func generateServerID() string {
	// Combine various hardware identifiers
	identifiers := []string{
		getMAC(),
		getCPUInfo(),
		getHostname(),
		getDiskSerial(),
		getMachineID(),
		getProductUUID(),
	}

	// Filter out empty identifiers
	validIdentifiers := make([]string, 0)
	for _, id := range identifiers {
		if id != "" {
			validIdentifiers = append(validIdentifiers, id)
		}
	}

	// Join all identifiers
	combinedString := strings.Join(validIdentifiers, "|")

	// Generate SHA-256 hash
	hash := sha256.New()
	hash.Write([]byte(combinedString))
	serverID := hex.EncodeToString(hash.Sum(nil))

	return serverID
}

func main() {
	// Generate and print the server ID
	serverID := generateServerID()
	fmt.Printf("Server Unique ID: %s\n", serverID)

	// Print individual components for debugging (optional)
	fmt.Println("\nComponent Information:")
	fmt.Printf("MAC Address: %s\n", getMAC())
	fmt.Printf("CPU Info: %s\n", getCPUInfo())
	fmt.Printf("Hostname: %s\n", getHostname())
	fmt.Printf("Disk ID: %s\n", getDiskSerial())
	fmt.Printf("Machine ID: %s\n", getMachineID())
	fmt.Printf("Product UUID: %s\n", getProductUUID())
}
```