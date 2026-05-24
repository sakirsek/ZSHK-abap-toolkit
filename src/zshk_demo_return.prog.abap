*&---------------------------------------------------------------------*
*& ZSHK_DEMO_RETURN — Return module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_return.

START-OF-SELECTION.

  " success / error / warning / info
  DATA(ls_ok)   = zcl_shk_return=>success( 'Record saved successfully' ).
  DATA(ls_err)  = zcl_shk_return=>error( 'Material not found' ).
  DATA(ls_warn) = zcl_shk_return=>warning( 'Quantity exceeds limit' ).
  DATA(ls_info) = zcl_shk_return=>info( '15 records processed' ).

  WRITE: / 'Factory methods:'.
  WRITE: / |  S: { ls_ok-message }|.
  WRITE: / |  E: { ls_err-message }|.
  WRITE: / |  W: { ls_warn-message }|.
  WRITE: / |  I: { ls_info-message }|.
  ULINE.

  " from_sy_msg
  MESSAGE s002(zshk_msg) WITH 'Test' INTO DATA(lv_dummy).
  DATA(ls_sy) = zcl_shk_return=>from_sy_msg( ).
  WRITE: / |from_sy_msg: { ls_sy-type } - { ls_sy-message }|.

  " from_exception
  TRY.
      RAISE EXCEPTION TYPE cx_sy_zerodivide.
    CATCH cx_root INTO DATA(lo_exc).
      DATA(ls_exc) = zcl_shk_return=>from_exception( lo_exc ).
      WRITE: / |from_exception: { ls_exc-type } - { ls_exc-message }|.
  ENDTRY.
  ULINE.

  " has_errors / collect_errors / to_string / table_to_string
  DATA lt_return TYPE bapiret2_t.
  APPEND ls_ok   TO lt_return.
  APPEND ls_err  TO lt_return.
  APPEND ls_warn TO lt_return.
  APPEND ls_info TO lt_return.
  APPEND ls_exc  TO lt_return.

  DATA(lv_has_err) = zcl_shk_return=>has_errors( lt_return ).
  WRITE: / |has_errors: { lv_has_err }|.

  DATA(lt_errs) = zcl_shk_return=>collect_errors( lt_return ).
  WRITE: / |Error count: { lines( lt_errs ) }|.
  LOOP AT lt_errs INTO DATA(ls_e).
    WRITE: / |  { zcl_shk_return=>to_string( ls_e ) }|.
  ENDLOOP.
  ULINE.

  " table_to_string
  DATA(lv_all) = zcl_shk_return=>table_to_string( lt_return ).
  WRITE: / 'All messages (newline separated):'.
  WRITE: / lv_all.
  ULINE.

  " table_to_string with custom separator
  DATA(lv_pipe) = zcl_shk_return=>table_to_string(
    it_return    = lt_return
    iv_separator = ' | ' ).
  WRITE: / 'Pipe separated:'.
  WRITE: / lv_pipe.
