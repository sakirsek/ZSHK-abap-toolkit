CLASS zcl_shk_progress DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_total TYPE i
        iv_text  TYPE clike DEFAULT 'Processing...'.

    METHODS update
      IMPORTING
        iv_current TYPE i OPTIONAL
        iv_text    TYPE clike OPTIONAL.

    METHODS increment
      IMPORTING
        iv_text TYPE clike OPTIONAL.

    METHODS get_percentage
      RETURNING VALUE(rv_pct) TYPE i.

    METHODS get_elapsed
      RETURNING VALUE(rv_seconds) TYPE i.

    METHODS get_eta
      RETURNING VALUE(rv_seconds) TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_total     TYPE i.
    DATA mv_current   TYPE i.
    DATA mv_text      TYPE string.
    DATA mv_start_ts  TYPE timestampl.

    METHODS show.
ENDCLASS.

CLASS zcl_shk_progress IMPLEMENTATION.
  METHOD constructor.
    mv_total   = iv_total.
    mv_current = 0.
    mv_text    = iv_text.
    GET TIME STAMP FIELD mv_start_ts.
  ENDMETHOD.

  METHOD update.
    IF iv_current IS SUPPLIED.
      mv_current = iv_current.
    ENDIF.
    IF iv_text IS SUPPLIED AND iv_text IS NOT INITIAL.
      mv_text = iv_text.
    ENDIF.
    show( ).
  ENDMETHOD.

  METHOD increment.
    mv_current = mv_current + 1.
    IF iv_text IS SUPPLIED AND iv_text IS NOT INITIAL.
      mv_text = iv_text.
    ENDIF.
    show( ).
  ENDMETHOD.

  METHOD get_percentage.
    IF mv_total > 0.
      rv_pct = mv_current * 100 / mv_total.
    ENDIF.
  ENDMETHOD.

  METHOD get_elapsed.
    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.
    rv_seconds = cl_abap_tstmp=>subtract(
      tstmp1 = lv_now
      tstmp2 = mv_start_ts ).
  ENDMETHOD.

  METHOD get_eta.
    DATA(lv_elapsed) = get_elapsed( ).
    IF mv_current > 0 AND mv_current < mv_total.
      rv_seconds = lv_elapsed * ( mv_total - mv_current ) / mv_current.
    ENDIF.
  ENDMETHOD.

  METHOD show.
    DATA(lv_pct) = get_percentage( ).
    DATA(lv_eta) = get_eta( ).

    DATA lv_display TYPE string.
    IF lv_eta > 0.
      DATA(lv_min) = lv_eta DIV 60.
      DATA(lv_sec) = lv_eta MOD 60.
      lv_display = |{ mv_text } ({ mv_current }/{ mv_total }) ~{ lv_min }m{ lv_sec }s|.
    ELSE.
      lv_display = |{ mv_text } ({ mv_current }/{ mv_total })|.
    ENDIF.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = lv_pct
        text       = lv_display.
  ENDMETHOD.
ENDCLASS.
