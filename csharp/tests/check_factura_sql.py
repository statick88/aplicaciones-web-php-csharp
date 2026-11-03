#!/usr/bin/env python3
"""HTTP and SQL Server proof for the invoice Mail required-field boundary."""

from __future__ import annotations

import argparse
import html
import json
import subprocess
import sys
import urllib.parse
import urllib.request
import uuid


FIELDS = ("Id", "NumeroFactura", "Cedula", "Nombre", "Telefono", "Direccion", "Mail")
REQUIRED_MESSAGE = "El correo es obligatorio."


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True, help="running invoice app URL")
    parser.add_argument("--sql-container", required=True, help="isolated SQL Server container name")
    return parser.parse_args()


def sql(container: str, query: str) -> str:
    command = [
        "docker", "exec", container, "sh", "-c",
        'SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -d Facturas -y 0 -Q "$1"',
        "sh", query,
    ]
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    if completed.returncode:
        raise AssertionError(f"SQL read failed: {completed.stderr.strip()}")
    return completed.stdout.strip()


def snapshot(container: str) -> tuple[list[dict[str, object]], int | None]:
    rows_text = sql(container, "SET NOCOUNT ON; SELECT Id, NumeroFactura, Cedula, Nombre, Telefono, Direccion, Mail FROM Facturas ORDER BY Id FOR JSON PATH;")
    counter_text = sql(container, "SET NOCOUNT ON; SELECT CAST(IDENT_CURRENT('Facturas') AS bigint);")
    return json.loads(rows_text or "[]"), None if counter_text == "NULL" else int(counter_text)


def request(base_url: str, fields: dict[str, str]) -> tuple[int, str]:
    data = urllib.parse.urlencode(fields).encode()
    request = urllib.request.Request(base_url.rstrip("/") + "/", data=data)
    with urllib.request.urlopen(request) as response:
        return response.status, html.unescape(response.read().decode())


def get(base_url: str) -> tuple[int, str]:
    with urllib.request.urlopen(base_url.rstrip("/") + "/") as response:
        return response.status, html.unescape(response.read().decode())


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    args = parse_args()
    suffix = uuid.uuid4().hex
    retained = {
        "NumeroFactura": f"FACTURA-PRUEBA-{suffix}",
        "Cedula": "9999999999",
        "Nombre": "Factura Ficticia",
        "Telefono": "0999999999",
        "Direccion": "Direccion Ficticia 123",
    }

    for label, mail in (("omitted", None), ("empty", ""), ("whitespace", "   ")):
        before_rows, before_counter = snapshot(args.sql_container)
        fields = dict(retained)
        if mail is not None:
            fields["Mail"] = mail
        status, body = request(args.base_url, fields)
        require(status == 200, f"{label}: expected HTTP 200, got {status}")
        require(REQUIRED_MESSAGE in body, f"{label}: required Mail message was not visible")
        require("Datos de la Factura" not in body, f"{label}: rejected form showed the success card")
        for value in retained.values():
            require(value in body, f"{label}: retained field value {value!r} was not visible")
        after_rows, after_counter = snapshot(args.sql_container)
        require(after_rows == before_rows, f"{label}: rejected input inserted or changed invoice rows")
        require(after_counter == before_counter, f"{label}: rejected input changed the identity counter")

    before_rows, before_counter = snapshot(args.sql_container)
    valid = {**retained, "NumeroFactura": f"FACTURA-VALIDA-{suffix}", "Mail": "factura.ficticia@example.test"}
    status, body = request(args.base_url, valid)
    require(status == 200, f"valid: expected HTTP 200, got {status}")
    require("Datos de la Factura" in body, "valid: success card was not visible")
    for value in valid.values():
        require(value in body, f"valid: submitted value {value!r} was not visible")
    after_rows, after_counter = snapshot(args.sql_container)
    require(len(after_rows) == len(before_rows) + 1, "valid: invoice row count did not increase by one")
    require(after_counter == (before_counter or 0) + 1, "valid: identity counter did not increase by one")
    saved = after_rows[-1]
    require(all(saved[field] == value for field, value in valid.items()), "valid: SQL row did not preserve all six submitted fields exactly")

    get_status, _ = get(args.base_url)
    require(get_status == 200, f"GET: expected HTTP 200, got {get_status}")
    final_rows, final_counter = snapshot(args.sql_container)
    require(final_rows == after_rows, "GET: changed invoice rows")
    require(final_counter == after_counter, "GET: changed identity counter")
    print("Invoice Mail validation proof passed: omitted, empty, whitespace, valid, and GET invariants.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, json.JSONDecodeError, subprocess.SubprocessError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
