"""Public configuration checks for the local Docker practice stack."""

from __future__ import annotations

import json
import re
import subprocess
import unittest
from pathlib import Path


CSHARP_DIR = Path(__file__).resolve().parents[1]


class RuntimeConfigurationTests(unittest.TestCase):
    def test_dockerfile_has_one_http_port_setting(self) -> None:
        dockerfile = (CSHARP_DIR / "Dockerfile").read_text(encoding="utf-8")

        self.assertNotRegex(dockerfile, r"(?m)^\s*ENV\s+ASPNETCORE_URLS(?:=|\s)")
        self.assertEqual(len(re.findall(r"(?m)^\s*ENV\s+ASPNETCORE_HTTP_PORTS=8080\s*$", dockerfile)), 1)

    def test_compose_persists_data_protection_keys_and_keeps_existing_mounts(self) -> None:
        result = subprocess.run(
            ["docker", "compose", "-f", "compose.yaml", "config", "--format", "json"],
            cwd=CSHARP_DIR,
            check=True,
            capture_output=True,
            text=True,
        )
        config = json.loads(result.stdout)
        app = config["services"]["app"]
        db = config["services"]["db"]

        self.assertIn("data-protection-keys", config["volumes"])
        self.assertIn(
            {"type": "volume", "source": "data-protection-keys", "target": "/root/.aspnet/DataProtection-Keys"},
            [
                {key: mount[key] for key in ("type", "source", "target") if key in mount}
                for mount in app["volumes"]
            ],
        )
        self.assertIn(
            {"type": "bind", "target": "/app"},
            [
                {key: mount[key] for key in ("type", "target") if key in mount}
                for mount in app["volumes"]
            ],
        )
        self.assertEqual(
            {mount["target"] for mount in app["volumes"] if mount["type"] == "volume"},
            {"/app/bin", "/app/obj", "/root/.aspnet/DataProtection-Keys"},
        )
        self.assertIn(
            {"type": "volume", "source": "db-data", "target": "/var/opt/mssql"},
            [
                {key: mount[key] for key in ("type", "source", "target") if key in mount}
                for mount in db["volumes"]
            ],
        )
        self.assertEqual(
            [{key: port[key] for key in ("host_ip", "published", "target", "protocol")} for port in app["ports"]],
            [{"host_ip": "127.0.0.1", "published": "8080", "target": 8080, "protocol": "tcp"}],
        )
        self.assertEqual(
            [{key: port[key] for key in ("host_ip", "published", "target", "protocol")} for port in db["ports"]],
            [{"host_ip": "127.0.0.1", "published": "1433", "target": 1433, "protocol": "tcp"}],
        )


if __name__ == "__main__":
    unittest.main()
