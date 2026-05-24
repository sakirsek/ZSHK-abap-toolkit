INTERFACE zif_shk_job PUBLIC.

  TYPES:
    BEGIN OF ty_s_step,
      program  TYPE sy-repid,
      variant  TYPE raldb_vari,
    END OF ty_s_step,

    BEGIN OF ty_s_schedule,
      immediate  TYPE abap_bool,
      start_date TYPE sy-datum,
      start_time TYPE sy-uzeit,
    END OF ty_s_schedule.

  METHODS set_name
    IMPORTING
      iv_name TYPE btcjob
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_job.

  METHODS add_step
    IMPORTING
      iv_program TYPE sy-repid
      iv_variant TYPE raldb_vari OPTIONAL
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_job.

  METHODS schedule_immediate
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_job.

  METHODS schedule_at
    IMPORTING
      iv_date TYPE sy-datum
      iv_time TYPE sy-uzeit
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_job.

  METHODS submit
    RETURNING
      VALUE(rv_jobcount) TYPE btcjobcnt
    RAISING
      zcx_shk_job.

  METHODS is_running
    IMPORTING
      iv_name          TYPE btcjob
    RETURNING
      VALUE(rv_running) TYPE abap_bool.

ENDINTERFACE.
