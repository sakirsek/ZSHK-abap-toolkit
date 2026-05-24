*&---------------------------------------------------------------------*
*& ZSHK_DEMO_JOB — Job module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_job.

PARAMETERS p_name TYPE btcjob DEFAULT 'ZSHK_DEMO_JOB'.
PARAMETERS p_prog TYPE sy-repid DEFAULT 'ZSHK_DEMO_DATE'.
PARAMETERS p_immed TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_date TYPE sy-datum.
PARAMETERS p_time TYPE sy-uzeit.
PARAMETERS p_run  TYPE abap_bool AS CHECKBOX.
PARAMETERS p_chk  TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.

  DATA(lo_job) = NEW zcl_shk_job( ).

  " is_running — check before submitting
  IF p_chk = abap_true.
    DATA(lv_running) = lo_job->zif_shk_job~is_running( p_name ).
    WRITE: / |Job "{ p_name }" running: { lv_running }|.
    ULINE.
  ENDIF.

  IF p_run = abap_false.
    WRITE: / 'Check "Submit" to actually schedule the job'.
    WRITE: / |Job name: { p_name }|.
    WRITE: / |Program:  { p_prog }|.
    IF p_immed = abap_true.
      WRITE: / 'Schedule: Immediate'.
    ELSE.
      WRITE: / |Schedule: { p_date DATE = USER } { p_time TIME = USER }|.
    ENDIF.
    RETURN.
  ENDIF.

  TRY.
      " set_name
      lo_job->zif_shk_job~set_name( p_name ).

      " add_step
      lo_job->zif_shk_job~add_step( iv_program = p_prog ).

      " schedule_immediate / schedule_at
      IF p_immed = abap_true.
        lo_job->zif_shk_job~schedule_immediate( ).
      ELSE.
        lo_job->zif_shk_job~schedule_at( iv_date = p_date iv_time = p_time ).
      ENDIF.

      " submit
      DATA(lv_jobcount) = lo_job->zif_shk_job~submit( ).
      WRITE: / |Job submitted! Count: { lv_jobcount }|.
      WRITE: / 'Check SM37 to monitor the job'.

    CATCH zcx_shk_job INTO DATA(lo_err).
      WRITE: / 'Job error:', lo_err->get_text( ).
  ENDTRY.
