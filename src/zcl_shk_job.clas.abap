CLASS zcl_shk_job DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_job.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_name     TYPE btcjob.
    DATA mv_jobcount TYPE btcjobcnt.
    DATA mt_steps    TYPE STANDARD TABLE OF zif_shk_job=>ty_s_step WITH EMPTY KEY.
    DATA ms_schedule TYPE zif_shk_job=>ty_s_schedule.
ENDCLASS.

CLASS zcl_shk_job IMPLEMENTATION.
  METHOD zif_shk_job~set_name.
    mv_name = iv_name.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_job~add_step.
    APPEND VALUE zif_shk_job=>ty_s_step(
      program = iv_program
      variant = iv_variant ) TO mt_steps.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_job~schedule_immediate.
    ms_schedule-immediate  = abap_true.
    ms_schedule-start_date = sy-datum.
    ms_schedule-start_time = sy-uzeit.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_job~schedule_at.
    ms_schedule-immediate  = abap_false.
    ms_schedule-start_date = iv_date.
    ms_schedule-start_time = iv_time.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_job~submit.
    IF mv_name IS INITIAL.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = 'Job name is required'.
    ENDIF.

    IF mt_steps IS INITIAL.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = 'At least one step is required'.
    ENDIF.

    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname          = mv_name
      IMPORTING
        jobcount         = mv_jobcount
      EXCEPTIONS
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        OTHERS           = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = |JOB_OPEN failed: { sy-msgv1 }|.
    ENDIF.

    LOOP AT mt_steps INTO DATA(ls_step).
      DATA lv_number TYPE btcstepcnt.

      CALL FUNCTION 'JOB_SUBMIT'
        EXPORTING
          authcknam               = sy-uname
          jobcount                = mv_jobcount
          jobname                 = mv_name
          report                  = ls_step-program
          variant                 = ls_step-variant
        IMPORTING
          step_number             = lv_number
        EXCEPTIONS
          bad_priparams           = 1
          bad_xpgflags            = 2
          invalid_jobdata         = 3
          jobname_missing         = 4
          job_notex               = 5
          job_submit_failed       = 6
          lock_failed             = 7
          step_number_not_found   = 8
          OTHERS                  = 9.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_shk_job
          EXPORTING iv_text = |JOB_SUBMIT failed for { ls_step-program }: { sy-msgv1 }|.
      ENDIF.
    ENDLOOP.

    DATA lv_start_date TYPE sy-datum.
    DATA lv_start_time TYPE sy-uzeit.

    IF ms_schedule-immediate = abap_true.
      CALL FUNCTION 'JOB_CLOSE'
        EXPORTING
          jobcount             = mv_jobcount
          jobname              = mv_name
          strtimmed            = abap_true
        EXCEPTIONS
          cant_start_immediate = 1
          invalid_startdate    = 2
          jobname_missing      = 3
          job_close_failed     = 4
          job_nosteps          = 5
          job_notex            = 6
          lock_failed          = 7
          invalid_target       = 8
          OTHERS               = 9.
    ELSE.
      lv_start_date = ms_schedule-start_date.
      lv_start_time = ms_schedule-start_time.

      CALL FUNCTION 'JOB_CLOSE'
        EXPORTING
          jobcount             = mv_jobcount
          jobname              = mv_name
          sdlstrtdt            = lv_start_date
          sdlstrttm            = lv_start_time
        EXCEPTIONS
          cant_start_immediate = 1
          invalid_startdate    = 2
          jobname_missing      = 3
          job_close_failed     = 4
          job_nosteps          = 5
          job_notex            = 6
          lock_failed          = 7
          invalid_target       = 8
          OTHERS               = 9.
    ENDIF.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = |JOB_CLOSE failed: { sy-msgv1 }|.
    ENDIF.

    rv_jobcount = mv_jobcount.
    CLEAR: mt_steps, ms_schedule.
  ENDMETHOD.

  METHOD zif_shk_job~is_running.
    DATA ls_sel TYPE btcselect.
    DATA lt_joblist TYPE STANDARD TABLE OF tbtcjob.

    ls_sel-jobname  = iv_name.
    ls_sel-username = '*'.
    ls_sel-running  = abap_true.
    ls_sel-from_date = sy-datum - 1.
    ls_sel-to_date   = sy-datum.

    CALL FUNCTION 'BP_JOB_SELECT'
      EXPORTING
        jobselect_dialog  = 'N'
        jobsel_param_in   = ls_sel
      TABLES
        jobselect_joblist = lt_joblist
      EXCEPTIONS
        OTHERS            = 1.

    rv_running = xsdbool( lt_joblist IS NOT INITIAL ).
  ENDMETHOD.
ENDCLASS.
