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
| **Job** | `ZCL_SHK_JOB` | Background job scheduler — open/submit/close, singleton lock check | Done |
| **Date** | `ZCL_SHK_DATE` | Factory calendar utilities — workday checks, add/subtract workdays, period | Done |
| **Progress** | `ZCL_SHK_PROGRESS` | Progress indicator with ETA estimation | Done |
| **Return** | `ZCL_SHK_RETURN` | BAPIRET2 factory — create from text/sy-msg/exception, collect errors | Done |
| **CSV** | `ZCL_SHK_CSV` | Internal table to CSV and back, Turkish charset support | Done |

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

### Job

```abap
DATA(lo_job) = NEW zcl_shk_job( ).
lo_job->zif_shk_job~set_name( 'ZREPORT_DAILY' )->add_step( iv_program = 'ZREPORT' iv_variant = 'V01' )->schedule_immediate( )->submit( ).
```

### Date

```abap
IF zcl_shk_date=>is_workday( ) = abap_true.
  DATA(lv_next) = zcl_shk_date=>add_workdays( iv_days = 5 ).
  DATA(lv_last_day) = zcl_shk_date=>get_month_last( ).
ENDIF.
```

### Progress

```abap
DATA(lo_prog) = NEW zcl_shk_progress( iv_total = lines( lt_data ) iv_text = 'Exporting' ).
LOOP AT lt_data INTO DATA(ls_data).
  lo_prog->increment( ).
  " ... process
ENDLOOP.
```

### Return

```abap
DATA(ls_err) = zcl_shk_return=>error( 'Material not found' ).
DATA(ls_ok)  = zcl_shk_return=>success( 'Saved' ).
DATA(ls_sy)  = zcl_shk_return=>from_sy_msg( ).
IF zcl_shk_return=>has_errors( lt_return ) = abap_true.
  DATA(lt_errs) = zcl_shk_return=>collect_errors( lt_return ).
ENDIF.
```

### CSV

```abap
DATA(lv_csv) = zcl_shk_csv=>table_to_csv( it_table = lt_data iv_separator = ';' ).
zcl_shk_csv=>csv_to_table( EXPORTING iv_csv = lv_csv CHANGING ct_table = lt_result ).
```

## Demo Programs

Each module has a runnable demo program (`SE38`):

| Program | Module | Notes |
|---|---|---|
| `ZSHK_DEMO_LOG` | Log | Standalone — creates and displays a sample log |
| `ZSHK_DEMO_BDC` | BDC | Opens SE16 via BDC — check "Execute" to run |
| `ZSHK_DEMO_MAIL` | Mail | Requires recipient — check "Send" to deliver |
| `ZSHK_DEMO_FTP` | FTP | Requires host/user/password |
| `ZSHK_DEMO_HTTP` | HTTP | Sends GET to httpbin.org by default |
| `ZSHK_DEMO_JOB` | Job | Schedules a background job — check "Submit" to run |
| `ZSHK_DEMO_DATE` | Date | Standalone — factory calendar calculations |
| `ZSHK_DEMO_PROGRESS` | Progress | Standalone — shows progress bar with ETA |
| `ZSHK_DEMO_RETURN` | Return | Standalone — BAPIRET2 factory and utilities |
| `ZSHK_DEMO_CSV` | CSV | Standalone — table/CSV round-trip conversion |

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
