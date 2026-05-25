# ZSHK ABAP Toolkit

Personal, portable ABAP utility library. Pull into any SAP system with [abapGit](https://abapgit.org/) — zero external dependencies.

Built for SAP NetWeaver 7.50+ and S/4HANA.

## Quick Start

```
1. Create package ZSHK in your SAP system (SE80 / SE21)
2. Open abapGit (ZABAPGIT or Eclipse ADT)
3. Clone: https://github.com/sakirsek/ZSHK-abap-toolkit.git
4. Pull into package ZSHK
```

That's it — all 10 modules are ready to use. No configuration required.

## Modules

| Module | Class | What it does |
|---|---|---|
| **Log** | `ZCL_SHK_LOG` | Application log with in-memory popup or persistent SLG1 storage |
| **BDC** | `ZCL_SHK_BDC` | Batch input recorder — build screens, fields, and run transactions |
| **Mail** | `ZCL_SHK_MAIL` | HTML emails with attachments, inline tables, CC/BCC via CL_BCS |
| **FTP** | `ZCL_SHK_FTP` | FTP client — upload, download, rename, delete, directory navigation |
| **HTTP** | `ZCL_SHK_HTTP` | REST client — GET/POST/PUT/DELETE with auth and custom headers |
| **Job** | `ZCL_SHK_JOB` | Background job scheduling with singleton lock check |
| **Date** | `ZCL_SHK_DATE` | Factory calendar — workday checks, date arithmetic, period helpers |
| **Progress** | `ZCL_SHK_PROGRESS` | Progress indicator with ETA estimation |
| **Return** | `ZCL_SHK_RETURN` | BAPIRET2 message factory — create, collect, and check return messages |
| **CSV** | `ZCL_SHK_CSV` | Internal table ↔ CSV conversion with Turkish charset support |

Every module follows the same pattern: **interface** (`ZIF_SHK_*`) + **class** (`ZCL_SHK_*`) + **exception** (`ZCX_SHK_*`).

## Usage Examples

### Log

```abap
" Zero-config: in-memory log with popup display
DATA(lo_log) = NEW zcl_shk_log( ).
lo_log->zif_shk_log~add_free_text( iv_text = 'Processing started' iv_type = 'I' ).
lo_log->zif_shk_log~add_bapiret2( ls_return ).
zcl_shk_log_gui=>show_by_messages( it_messages = lo_log->get_messages( ) iv_title = 'Results' ).

" Persistent: saved to DB, viewable in SLG1
DATA(lo_plog) = NEW zcl_shk_log( iv_object = 'ZSHK' ).
lo_plog->zif_shk_log~add_free_text( 'Saved to SLG1' ).
lo_plog->zif_shk_log~save( ).
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
lo_mail->zif_shk_mail~set_subject( 'Monthly Report' ).
lo_mail->zif_shk_mail~set_body_html( lv_html ).
lo_mail->zif_shk_mail~add_table( it_table = lt_data iv_title = 'Order List' ).
lo_mail->zif_shk_mail~add_recipient( 'user@example.com' ).
lo_mail->zif_shk_mail~send( ).
```

### FTP

```abap
DATA(lo_ftp) = NEW zcl_shk_ftp( iv_host = '10.0.0.1' iv_user = 'ftpuser' iv_password = 'pass' ).
lo_ftp->zif_shk_ftp~connect( ).
lo_ftp->zif_shk_ftp~set_passive( abap_true ).
lo_ftp->zif_shk_ftp~cd( 'incoming' ).
lo_ftp->zif_shk_ftp~upload( iv_remote_path = 'export.csv' iv_content = lv_xstring ).
lo_ftp->zif_shk_ftp~rename_file( iv_from = 'export.csv' iv_to = 'Archive/export.csv' ).
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
lo_job->zif_shk_job~set_name( 'ZREPORT_DAILY' ).
lo_job->zif_shk_job~add_step( iv_program = 'ZREPORT' iv_variant = 'V01' ).
lo_job->zif_shk_job~schedule_immediate( ).
lo_job->zif_shk_job~submit( ).
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
  " ... process ls_data
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

Each module comes with a runnable demo program. Open in `SE38` to see it in action:

| Program | What it shows |
|---|---|
| `ZSHK_DEMO_LOG` | Creates sample log entries and displays them in a popup |
| `ZSHK_DEMO_BDC` | Runs SE16 via batch input |
| `ZSHK_DEMO_MAIL` | Composes and sends an HTML email with a table |
| `ZSHK_DEMO_FTP` | Connects to an FTP server, uploads, downloads, and renames files |
| `ZSHK_DEMO_HTTP` | Sends a GET request to httpbin.org |
| `ZSHK_DEMO_JOB` | Schedules and submits a background job |
| `ZSHK_DEMO_DATE` | Factory calendar calculations for today |
| `ZSHK_DEMO_PROGRESS` | Shows a progress bar with ETA |
| `ZSHK_DEMO_RETURN` | Builds BAPIRET2 messages and checks for errors |
| `ZSHK_DEMO_CSV` | Converts a table to CSV and back |

## Design

- **Zero dependencies** — only SAP standard classes and function modules
- **Self-contained modules** — no cross-dependencies, use any subset you need
- **Interface-first** — `ZIF_SHK_*` interfaces for testability and mocking
- **One exception per module** — consistent error handling via `ZCX_SHK_*`
- **Only wrap what hurts** — if SAP standard is clean enough, no extra layer

## Naming Convention

```
ZCL_SHK_<MODULE>     Classes         ZCL_SHK_LOG, ZCL_SHK_MAIL
ZIF_SHK_<MODULE>     Interfaces      ZIF_SHK_LOG, ZIF_SHK_MAIL
ZCX_SHK_<MODULE>     Exceptions      ZCX_SHK_LOG, ZCX_SHK_MAIL
ZSHK_DEMO_<MODULE>   Demo programs   ZSHK_DEMO_LOG, ZSHK_DEMO_MAIL
```

## Requirements

- SAP NetWeaver 7.50+ or S/4HANA (any edition)
- [abapGit](https://abapgit.org/)

## License

[MIT](LICENSE)
