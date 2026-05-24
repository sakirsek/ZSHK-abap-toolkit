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
    DATA lv_type TYPE scal-indicator.

    CALL FUNCTION 'DAY_ATTRIBUTES_GET'
      EXPORTING
        factory_calendar = iv_factory_cal_id
        from             = iv_date
        to               = iv_date
      IMPORTING
        day_attributes   = lv_type
      EXCEPTIONS
        OTHERS           = 1.

    rv_result = xsdbool( sy-subrc = 0 AND lv_type IS INITIAL ).
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
    rv_count = 0.

    CALL FUNCTION 'RKE_SELECT_FACTDAYS_FOR_PERIOD'
      EXPORTING
        i_datab        = iv_from
        i_datbi        = iv_to
        i_factoryid    = iv_factory_cal_id
      IMPORTING
        e_facdays      = rv_count
      EXCEPTIONS
        OTHERS         = 1.
  ENDMETHOD.
ENDCLASS.
