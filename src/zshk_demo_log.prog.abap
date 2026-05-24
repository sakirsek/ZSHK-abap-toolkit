*&---------------------------------------------------------------------*
*& ZSHK_DEMO_LOG — Log module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_log.

START-OF-SELECTION.

  DATA(lo_log) = NEW zcl_shk_log(
    iv_object    = 'APPL_LOG'
    iv_extnumber = 'ZSHK_DEMO' ).

  " add_free_text
  lo_log->zif_shk_log~add_free_text( iv_text = 'Process started' iv_type = 'I' ).
  lo_log->zif_shk_log~add_free_text( iv_text = 'Step 1 completed' iv_type = 'S' ).
  lo_log->zif_shk_log~add_free_text( iv_text = 'Warning: threshold reached' iv_type = 'W' ).
  lo_log->zif_shk_log~add_free_text( iv_text = 'Error: record not found' iv_type = 'E' ).

  " add_bapiret2
  DATA ls_return TYPE bapiret2.
  ls_return-type       = 'E'.
  ls_return-id         = 'ZSHK_MSG'.
  ls_return-number     = '003'.
  ls_return-message    = 'Object MATERIAL not found'.
  ls_return-message_v1 = 'MATERIAL'.
  lo_log->zif_shk_log~add_bapiret2( ls_return ).

  " add_bapiret2_table
  DATA lt_return TYPE bapiret2_t.
  ls_return-type    = 'S'.
  ls_return-message = 'Line 1 saved'.
  APPEND ls_return TO lt_return.
  ls_return-type    = 'W'.
  ls_return-message = 'Line 2 has issues'.
  APPEND ls_return TO lt_return.
  lo_log->zif_shk_log~add_bapiret2_table( lt_return ).

  " add_sy_msg
  MESSAGE s001(zshk_msg) WITH 'SY-MSG demo' INTO DATA(lv_dummy).
  lo_log->zif_shk_log~add_sy_msg( ).

  " add_exception
  TRY.
      RAISE EXCEPTION TYPE zcx_shk_log
        EXPORTING iv_text = 'Simulated exception for demo'.
    CATCH zcx_shk_log INTO DATA(lo_exc).
      lo_log->zif_shk_log~add_exception( io_exception = lo_exc iv_type = 'E' ).
  ENDTRY.

  " get_count / has_errors
  DATA(lv_count) = lo_log->zif_shk_log~get_count( ).
  DATA(lv_has_err) = lo_log->zif_shk_log~has_errors( ).
  WRITE: / |Message count: { lv_count }|.
  WRITE: / |Has errors: { lv_has_err }|.

  " get_messages
  DATA(lt_messages) = lo_log->zif_shk_log~get_messages( ).
  WRITE: / |Messages retrieved: { lines( lt_messages ) }|.

  " save + GUI display
  TRY.
      DATA(lv_handle) = lo_log->zif_shk_log~save( ).
      WRITE: / |Log saved, handle: { lv_handle }|.

      " show_by_handle
      zcl_shk_log_gui=>show_by_handle( lv_handle ).

    CATCH zcx_shk_log INTO DATA(lo_save_err).
      WRITE: / |Save error: { lo_save_err->get_text( ) }|.
  ENDTRY.

  " show_by_messages (without save)
  DATA(lo_log2) = NEW zcl_shk_log( ).
  lo_log2->zif_shk_log~add_free_text( 'Direct message display' ).
  zcl_shk_log_gui=>show_by_messages(
    it_messages = lo_log2->zif_shk_log~get_messages( )
    iv_title    = 'Direct Display Demo' ).

  " clear
  lo_log2->zif_shk_log~clear( ).
  WRITE: / |After clear, count: { lo_log2->zif_shk_log~get_count( ) }|.
