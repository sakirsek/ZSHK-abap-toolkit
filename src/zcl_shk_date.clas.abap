CLASS zcl_shk_date DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS is_workday
      IMPORTING
        iv_date           TYPE sy-datum DEFAULT sy-datum
        iv_factory_cal_id TYPE scal-fcalid DEFAULT 'TR'
      RETURNING
        VALUE(rv_result)  TYPE abap_bool.

    CLASS-METHODS get_next_workday
      IMPORTING
        iv_date           TYPE sy-datum DEFAULT sy-datum
        iv_factory_cal_id TYPE scal-fcalid DEFAULT 'TR'
      RETURNING
        VALUE(rv_date)    TYPE sy-datum.

    CLASS-METHODS get_prev_workday
      IMPORTING
        iv_date           TYPE sy-datum DEFAULT sy-datum
        iv_factory_cal_id TYPE scal-fcalid DEFAULT 'TR'
      RETURNING
        VALUE(rv_date)    TYPE sy-datum.

    CLASS-METHODS add_workdays
      IMPORTING
        iv_date           TYPE sy-datum DEFAULT sy-datum
        iv_days           TYPE i
        iv_factory_cal_id TYPE scal-fcalid DEFAULT 'TR'
      RETURNING
        VALUE(rv_date)    TYPE sy-datum.

    CLASS-METHODS get_month_first
      IMPORTING
        iv_date        TYPE sy-datum DEFAULT sy-datum
      RETURNING
        VALUE(rv_date) TYPE sy-datum.

    CLASS-METHODS get_month_last
      IMPORTING
        iv_date        TYPE sy-datum DEFAULT sy-datum
      RETURNING
        VALUE(rv_date) TYPE sy-datum.

    CLASS-METHODS get_period
      IMPORTING
        iv_date          TYPE sy-datum DEFAULT sy-datum
      RETURNING
        VALUE(rv_period) TYPE spmon.

    CLASS-METHODS get_workdays_between
      IMPORTING
        iv_from           TYPE sy-datum
        iv_to             TYPE sy-datum
        iv_factory_cal_id TYPE scal-fcalid DEFAULT 'TR'
      RETURNING
        VALUE(rv_count)   TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shk_date IMPLEMENTATION.
  METHOD is_workday.
    CALL FUNCTION 'DATE_CHECK_WORKINGDAY'
      EXPORTING
        date                       = iv_date
        factory_calendar_id        = iv_factory_cal_id
        message_type               = 'E'
      EXCEPTIONS
        date_after_range           = 1
        date_before_range          = 2
        date_invalid               = 3
        date_no_workingday         = 4
        factory_calendar_not_found = 5
        message_type_invalid       = 6
        OTHERS                     = 7.

    rv_result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD get_next_workday.
    rv_date = iv_date + 1.

    CALL FUNCTION 'BKK_ADD_WORKINGDAY'
      EXPORTING
        i_date       = iv_date
        i_days       = 1
        i_calendar1  = iv_factory_cal_id
      IMPORTING
        e_date       = rv_date
      EXCEPTIONS
        OTHERS       = 1.
  ENDMETHOD.

  METHOD get_prev_workday.
    rv_date = iv_date - 1.

    CALL FUNCTION 'BKK_ADD_WORKINGDAY'
      EXPORTING
        i_date       = iv_date
        i_days       = -1
        i_calendar1  = iv_factory_cal_id
      IMPORTING
        e_date       = rv_date
      EXCEPTIONS
        OTHERS       = 1.
  ENDMETHOD.

  METHOD add_workdays.
    rv_date = iv_date.

    CALL FUNCTION 'BKK_ADD_WORKINGDAY'
      EXPORTING
        i_date       = iv_date
        i_days       = iv_days
        i_calendar1  = iv_factory_cal_id
      IMPORTING
        e_date       = rv_date
      EXCEPTIONS
        OTHERS       = 1.
  ENDMETHOD.

  METHOD get_month_first.
    rv_date = iv_date.
    rv_date+6(2) = '01'.
  ENDMETHOD.

  METHOD get_month_last.
    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = iv_date
      IMPORTING
        last_day_of_month = rv_date
      EXCEPTIONS
        OTHERS            = 1.

    IF sy-subrc <> 0.
      rv_date = iv_date.
    ENDIF.
  ENDMETHOD.

  METHOD get_period.
    rv_period = iv_date+0(4) && iv_date+4(2).
  ENDMETHOD.

  METHOD get_workdays_between.
    DATA lt_dats TYPE STANDARD TABLE OF rke_dat.

    CALL FUNCTION 'RKE_SELECT_FACTDAYS_FOR_PERIOD'
      EXPORTING
        i_datab               = iv_from
        i_datbi               = iv_to
        i_factid              = iv_factory_cal_id
      TABLES
        eth_dats              = lt_dats
      EXCEPTIONS
        date_conversion_error = 1
        OTHERS                = 2.

    IF sy-subrc = 0.
      rv_count = lines( lt_dats ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
