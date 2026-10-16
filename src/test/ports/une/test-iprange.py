#!/usr/bin/env python3
"""Check the opt-in IPv4 example, including malformed and maximum-length inputs."""

import ipaddress
import subprocess
import sys

program = sys.argv[1]
for value in ("0.0.0.0/0", "255.255.255.255/32", "1.2.3.4/22",
              "192.0.2.129/25", "128.0.0.0/1"):
    network = ipaddress.ip_network(value, strict=False)
    result = subprocess.run([program, value], capture_output=True, text=True,
                            check=True, timeout=10)
    expected = (f"Network:{network.network_address}\n"
                f"Mask:   {network.netmask}\n"
                f"First:  {network.network_address}\n"
                f"Last:   {network.broadcast_address}\n")
    assert result.stdout == expected, (value, result.stdout, expected)

for value in ("", ".2.3.4/24", "1..3.4/24", "1.2.3./24", "1.2.3.4/",
              "1.2.3.4/24junk", "1.2.3.4/33", "256.2.3.4/24",
              "999999999999999999999.2.3.4/24", "1.2.3.4/24/1",
              "0" * 53 + "1.2.3.4/24junk"):
    result = subprocess.run([program, value], capture_output=True, timeout=10)
    assert result.returncode != 0, (value, result.stdout)

print("IPv4 subnet and malformed-input checks passed")
