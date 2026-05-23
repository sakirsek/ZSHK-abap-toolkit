# ZSHK ABAP Toolkit

Reusable ABAP utility toolkit. Zero dependencies, S/4HANA compatible (7.50+).

Personal, portable library — pull into any SAP system via [abapGit](https://abapgit.org/).

## Modules

| Module | Class | Description | Status |
|---|---|---|---|
| **Log** | `ZCL_SHK_LOG` | Application log wrapper (BAL) — add messages in any format, save, display | Planned |
| **Mail** | `ZCL_SHK_MAIL` | Email via CL_BCS — HTML body, attachments (PDF/Excel/CSV), CC/BCC | Planned |
| **FTP** | `ZCL_SHK_FTP` | FTP upload/download, directory listing, error handling | Planned |
| **HTTP** | `ZCL_SHK_HTTP` | REST client — GET/POST/PUT/DELETE, JSON, timeout, Turkish charset | Planned |
| **BDC** | `ZCL_SHK_BDC` | Batch Data Communication wrapper — screen/field builder, BAPIRET2 errors | Planned |

## Installation

1. Create package `ZSHK` in your SAP system (SE80 / SE21)
2. Open abapGit (SE38 → `ZABAPGIT` or Eclipse ADT)
3. Clone this repository: `https://github.com/sakirsek/ZSHK-abap-toolkit.git`
4. Pull into package `ZSHK`

## Requirements

- SAP NetWeaver 7.50+ or S/4HANA (any edition)
- abapGit installed
- No external dependencies

## Design Principles

- **Zero dependencies** — only SAP standard classes and function modules
- **Each class is self-contained** — no cross-dependencies between modules
- **Interface-first** — `ZIF_SHK_*` interfaces for testability and mocking
- **Multiton + lazy init** — cache repeated lookups, load on first access
- **Minimal exceptions** — one exception class per module (`ZCX_SHK_*`)
- **Don't wrap what's already good** — if SAP standard is clean enough (e.g., CL_SALV_TABLE), don't add a layer

## Naming Convention

```
ZCL_SHK_<MODULE>     Classes         (e.g., ZCL_SHK_LOG)
ZIF_SHK_<MODULE>     Interfaces      (e.g., ZIF_SHK_LOG)
ZCX_SHK_<MODULE>     Exceptions      (e.g., ZCX_SHK_LOG)
ZSHK_S_<NAME>        Structures
ZSHK_T_<NAME>        Table types
```

## License

[MIT](LICENSE)
