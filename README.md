# ZSHK ABAP Toolkit

Reusable ABAP utility toolkit. Zero dependencies, S/4HANA compatible (7.50+).

Personal, portable library — pull into any SAP system via [abapGit](https://abapgit.org/).

## Modules

| Module | Class | Description | Status |
|---|---|---|---|
| **Log** | `ZCL_SHK_LOG`, `ZCL_SHK_LOG_GUI` | Application log wrapper (BAL) — add messages in any format, save, display | Done |
| **BDC** | `ZCL_SHK_BDC` | Batch Data Communication wrapper — screen/field builder, BAPIRET2 errors | Done |
| **Mail** | `ZCL_SHK_MAIL` | Email via CL_BCS — HTML body, attachments (PDF/Excel/CSV), CC/BCC | Done |
| **FTP** | `ZCL_SHK_FTP` | FTP upload/download, directory listing, error handling | Done |
| **HTTP** | `ZCL_SHK_HTTP` | REST client — GET/POST/PUT/DELETE, JSON, timeout, Turkish charset | Done |

## Usage

### Log

```abap
DATA(lo_log) = NEW zcl_shk_log( iv_object = 'ZAPPL' iv_subobject = 'TEST' ).
lo_log->zif_shk_log~add_free_text( iv_text = 'Processing started' iv_type = 'I' ).
lo_log->zif_shk_log~add_sy_msg( ).
lo_log->zif_shk_log~add_bapiret2( ls_return ).
DATA(lv_handle) = lo_log->zif_shk_log~save( ).
zcl_shk_log_gui=>show_by_handle( lv_handle ).
```

### BDC

```abap
DATA(lo_bdc) = NEW zcl_shk_bdc( ).
lo_bdc->zif_shk_bdc~add_screen( iv_program = 'SAPMM06E' iv_dynpro = '0100' ).
lo_bdc->zif_shk_bdc~add_field( iv_name = 'RM06E-BSART' iv_value = 'NB' ).
lo_bdc->zif_shk_bdc~add_okcode( '=ENTER' ).
DATA(lt_msg) = lo_bdc->zif_shk_bdc~execute( iv_tcode = 'ME21N' ).
```

### Mail

```abap
DATA(lo_mail) = NEW zcl_shk_mail( ).
lo_mail->zif_shk_mail~set_subject( 'Report' )->set_body_html( lv_html )->add_recipient( 'user@example.com' )->send( ).
```

### FTP

```abap
DATA(lo_ftp) = NEW zcl_shk_ftp( iv_host = '10.0.0.1' iv_user = 'ftpuser' iv_password = 'pass' ).
lo_ftp->zif_shk_ftp~connect( ).
lo_ftp->zif_shk_ftp~upload( iv_remote_path = '/data/export.csv' iv_content = lv_xstring ).
lo_ftp->zif_shk_ftp~disconnect( ).
```

### HTTP

```abap
DATA(lo_http) = NEW zcl_shk_http( iv_url = 'https://api.example.com' ).
lo_http->zif_shk_http~set_basic_auth( iv_user = 'user' iv_password = 'pass' ).
DATA(ls_resp) = lo_http->zif_shk_http~post( iv_path = '/orders' iv_body = lv_json ).
```

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
