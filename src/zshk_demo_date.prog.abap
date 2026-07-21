*&---------------------------------------------------------------------*
*& ZSHK_DEMO_DATE — Date module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_date.

PARAMETERS p_date TYPE sy-datum DEFAULT sy-datum.
PARAMETERS p_cal  TYPE scal-fcalid DEFAULT 'TR'.
PARAMETERS p_days TYPE i DEFAULT 5.
PARAMETERS p_to   TYPE sy-datum.

START-OF-SELECTION.

  WRITE: / |Input date: { p_date DATE = USER }|.
  WRITE: / |Factory calendar: { p_cal }|.
  ULINE.

  " is_workday
  DATA(lv_workday) = zcl_shk_date=>is_workday( iv_date = p_date iv_factory_cal_id = p_cal ).
  WRITE: / |Is workday: { lv_workday }|.

  " get_next_workday
  DATA(lv_next) = zcl_shk_date=>get_next_workday( iv_date = p_date iv_factory_cal_id = p_cal ).
  WRITE: / |Next workday: { lv_next DATE = USER }|.

  " get_prev_workday
  DATA(lv_prev) = zcl_shk_date=>get_prev_workday( iv_date = p_date iv_factory_cal_id = p_cal ).
  WRITE: / |Prev workday: { lv_prev DATE = USER }|.

  " add_workdays
  DATA(lv_added) = zcl_shk_date=>add_workdays(
    iv_date = p_date iv_days = p_days iv_factory_cal_id = p_cal ).
  WRITE: / |+{ p_days } workdays: { lv_added DATE = USER }|.

  DATA(lv_sub) = zcl_shk_date=>add_workdays(
    iv_date = p_date iv_days = p_days * -1 iv_factory_cal_id = p_cal ).
  WRITE: / |-{ p_days } workdays: { lv_sub DATE = USER }|.

  ULINE.

  " get_month_first / get_month_last
  DATA(lv_first) = zcl_shk_date=>get_month_first( p_date ).
  DATA(lv_last) = zcl_shk_date=>get_month_last( p_date ).
  WRITE: / |Month first: { lv_first DATE = USER }|.
  WRITE: / |Month last:  { lv_last DATE = USER }|.

  " get_period
  DATA(lv_period) = zcl_shk_date=>get_period( p_date ).
  WRITE: / |Period: { lv_period }|.

  ULINE.

  " get_workdays_between
  IF p_to IS NOT INITIAL.
    DATA(lv_count) = zcl_shk_date=>get_workdays_between(
      iv_from = p_date iv_to = p_to iv_factory_cal_id = p_cal ).
    WRITE: / |Workdays between { p_date DATE = USER } - { p_to DATE = USER }: { lv_count }|.
  ELSE.
    DATA(lv_count2) = zcl_shk_date=>get_workdays_between(
      iv_from = lv_first iv_to = lv_last iv_factory_cal_id = p_cal ).
    WRITE: / |Workdays this month: { lv_count2 }|.
  ENDIF.

  ULINE.

  " get_timestamp_ms — local-time YYYYMMDDHHMMSSmmm (17 chars, ms precision)
  DATA(lv_ts) = zcl_shk_date=>get_timestamp_ms( ).
  WRITE: / |Timestamp (ms): { lv_ts }|.

  " add_timestamp_suffix — inserts _<timestamp> before the extension
  DATA(lv_fname1) = zcl_shk_date=>add_timestamp_suffix( `BOM.csv` ).
  WRITE: / |BOM.csv      -> { lv_fname1 }|.

  " no extension -> appended at the end
  DATA(lv_fname2) = zcl_shk_date=>add_timestamp_suffix( `report` ).
  WRITE: / |report       -> { lv_fname2 }|.
