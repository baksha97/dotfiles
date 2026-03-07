---
name: health-check
description: Monitors system resources (disk, memory, CPU) and network latency with a real-time dashboard.
---

# System Health Check

Use this skill to quickly assess the health of the local machine and network.

## Usage

Run with live browser dashboard:
```bash
just -f health-check/Justfile dashboard
```

Run in parallel in terminal:
```bash
just -f health-check/Justfile parallel
```

## Dashboard Features

- **Disk Space**: Shows filesystem usage.
- **Memory Status**: Displays free/used RAM.
- **CPU Load**: Shows system uptime and load average.
- **Network Ping**: Verifies connectivity to 8.8.8.8.
- **Env Variable Check**: Validates that custom task environment variables are correctly injected.
