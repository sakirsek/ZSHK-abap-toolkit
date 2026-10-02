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

    METHODS submit_with_params
      IMPORTING
        is_step TYPE zif_shk_job=>ty_s_step
      RAISING
        zcx_shk_job.
ENDCLASS.

CLASS zcl_shk_job IMPLEMENTATION.
  METHOD zif_shk_job~set_name.
    mv_name = iv_name.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_job~add_step.
    APPEND VALUE zif_shk_job=>ty_s_step(
      program = iv_program
      variant = iv_variant
      params  = it_params ) TO mt_steps.
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

  METHOD zif_shk_job~set_period.
    ms_schedule-period_min = iv_minutes.
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

    IF ms_schedule-period_min < 0 OR ms_schedule-period_min > 5999.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = 'Period must be between 0 and 5999 minutes'.
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
      IF ls_step-params IS NOT INITIAL.
        submit_with_params( ls_step ).
        CONTINUE.
      ENDIF.

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
    DATA lv_prdhours TYPE btcphour.
    DATA lv_prdmins TYPE btcpmin.

    lv_prdhours = ms_schedule-period_min DIV 60.
    lv_prdmins  = ms_schedule-period_min MOD 60.

    IF ms_schedule-immediate = abap_true.
      CALL FUNCTION 'JOB_CLOSE'
        EXPORTING
          jobcount             = mv_jobcount
          jobname              = mv_name
          strtimmed            = abap_true
          prdhours             = lv_prdhours
          prdmins              = lv_prdmins
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
          prdhours             = lv_prdhours
          prdmins              = lv_prdmins
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

  METHOD zif_shk_job~is_scheduled.
    " S released, Z released/suspended, Y ready, R active
    SELECT SINGLE jobcount FROM tbtco
      WHERE jobname = @iv_name
        AND status IN ('S','Z','Y','R')
      INTO @DATA(lv_jobcount).
    rv_scheduled = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_shk_job~delete_scheduled.
    " P scheduled, S released, Z released/suspended; ready and active jobs are left alone
    SELECT jobcount FROM tbtco
      WHERE jobname = @iv_name
        AND status IN ('P','S','Z')
      INTO TABLE @DATA(lt_jobs).

    LOOP AT lt_jobs INTO DATA(ls_job).
      CALL FUNCTION 'BP_JOB_DELETE'
        EXPORTING
          jobcount                 = ls_job-jobcount
          jobname                  = iv_name
        EXCEPTIONS
          cant_delete_event_entry  = 1
          cant_delete_job          = 2
          cant_delete_joblog       = 3
          cant_delete_steps        = 4
          cant_delete_time_entry   = 5
          cant_derelease_successor = 6
          cant_enq_predecessor     = 7
          cant_enq_successor       = 8
          cant_enq_tbtco_entry     = 9
          cant_update_predecessor  = 10
          cant_update_successor    = 11
          commit_failed            = 12
          jobcount_missing         = 13
          jobname_missing          = 14
          job_does_not_exist       = 15
          job_is_already_running   = 16
          no_delete_authority      = 17
          OTHERS                   = 18.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_shk_job
          EXPORTING iv_text = |BP_JOB_DELETE failed for { iv_name } { ls_job-jobcount } (sy-subrc { sy-subrc })|.
      ENDIF.
      rv_deleted = rv_deleted + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD submit_with_params.
    IF is_step-variant IS INITIAL.
      SUBMIT (is_step-program)
        WITH SELECTION-TABLE is_step-params
        VIA JOB mv_name NUMBER mv_jobcount
        AND RETURN.
    ELSE.
      SUBMIT (is_step-program)
        USING SELECTION-SET is_step-variant
        WITH SELECTION-TABLE is_step-params
        VIA JOB mv_name NUMBER mv_jobcount
        AND RETURN.
    ENDIF.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_job
        EXPORTING iv_text = |SUBMIT VIA JOB failed for { is_step-program } (sy-subrc { sy-subrc })|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
