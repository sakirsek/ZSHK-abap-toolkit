*&---------------------------------------------------------------------*
*& ZSHK_DEMO_JOB — Job module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_job.

PARAMETERS p_name TYPE btcjob DEFAULT 'ZSHK_DEMO_JOB'.
PARAMETERS p_prog TYPE sy-repid DEFAULT 'ZSHK_DEMO_DATE'.
PARAMETERS p_immed TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_date TYPE sy-datum.
PARAMETERS p_time TYPE sy-uzeit.
PARAMETERS p_per  TYPE i.
PARAMETERS p_selnm TYPE rsparams-selname.
PARAMETERS p_selvl TYPE rsparams-low.
PARAMETERS p_run  TYPE abap_bool AS CHECKBOX.
PARAMETERS p_chk  TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.

  DATA(lo_job) = NEW zcl_shk_job( ).

  " is_running / is_scheduled — check before submitting
  IF p_chk = abap_true.
    DATA(lv_running) = lo_job->zif_shk_job~is_running( p_name ).
    DATA(lv_scheduled) = lo_job->zif_shk_job~is_scheduled( p_name ).
    WRITE: / |Job "{ p_name }" running: { lv_running }|.
    WRITE: / |Job "{ p_name }" released/ready/running: { lv_scheduled }|.
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
    IF p_per > 0.
      WRITE: / |Period:   every { p_per } minutes|.
    ENDIF.
    IF p_selnm IS NOT INITIAL.
      WRITE: / |Param:    { p_selnm } = { p_selvl }|.
    ENDIF.
    RETURN.
  ENDIF.

  TRY.
      " set_name
      lo_job->zif_shk_job~set_name( p_name ).

      " add_step — optional selection-screen value (SUBMIT ... VIA JOB)
      DATA(lt_params) = COND rsparams_tt(
        WHEN p_selnm IS NOT INITIAL
        THEN VALUE #( ( selname = p_selnm kind = 'P' sign = 'I' option = 'EQ' low = p_selvl ) ) ).
      lo_job->zif_shk_job~add_step( iv_program = p_prog
                                    it_params  = lt_params ).

      " schedule_immediate / schedule_at
      IF p_immed = abap_true.
        lo_job->zif_shk_job~schedule_immediate( ).
      ELSE.
        lo_job->zif_shk_job~schedule_at( iv_date = p_date iv_time = p_time ).
      ENDIF.

      " set_period — 0 = one-off job
      lo_job->zif_shk_job~set_period( p_per ).

      " submit
      DATA(lv_jobcount) = lo_job->zif_shk_job~submit( ).
      WRITE: / |Job submitted! Count: { lv_jobcount }|.
      WRITE: / 'Check SM37 to monitor the job'.

    CATCH zcx_shk_job INTO DATA(lo_err).
      WRITE: / 'Job error:', lo_err->get_text( ).
  ENDTRY.
