*&---------------------------------------------------------------------*
*& ZSHK_DEMO_LOG — Log module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_log.

PARAMETERS p_obj TYPE balobj_d DEFAULT 'ZSHK'.

START-OF-SELECTION.

  " ============================================================
  " 1) In-memory log (zero config — no SLG0 dependency)
  " ============================================================
  DATA(lo_log) = NEW zcl_shk_log( iv_extnumber = 'ZSHK_DEMO' ).

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
  WRITE: / |Message count: { lo_log->zif_shk_log~get_count( ) }|.
  WRITE: / |Has errors: { lo_log->zif_shk_log~has_errors( ) }|.

  " show_by_messages — in-memory popup
  zcl_shk_log_gui=>show_by_messages(
    it_messages = lo_log->zif_shk_log~get_messages( )
    iv_title    = 'In-Memory Log Demo' ).

  " save — object empty, DB save skipped
  TRY.
      DATA(lv_handle) = lo_log->zif_shk_log~save( ).
      WRITE: / |save (in-memory): handle = { lv_handle }|.
      zcl_shk_log_gui=>show_by_handle( lv_handle ).
    CATCH zcx_shk_log INTO DATA(lo_err1).
      WRITE: / |Error: { lo_err1->get_text( ) }|.
  ENDTRY.

  " ============================================================
  " 2) Persistent log (SLG0 object — saved to DB, viewable in SLG1)
  " ============================================================
  IF p_obj IS NOT INITIAL.
    DATA(lo_plog) = NEW zcl_shk_log( iv_object = p_obj iv_extnumber = 'PERSISTENT_DEMO' ).
    lo_plog->zif_shk_log~add_free_text( iv_text = 'This log is saved to SLG1' iv_type = 'I' ).
    lo_plog->zif_shk_log~add_free_text( iv_text = 'Check SLG1 after execution' iv_type = 'S' ).
    TRY.
        DATA(lv_phandle) = lo_plog->zif_shk_log~save( ).
        WRITE: / |save (persistent): handle = { lv_phandle }|.
        WRITE: / |Check SLG1: Object = { p_obj }, ExtID = PERSISTENT_DEMO|.
        zcl_shk_log_gui=>show_by_handle( lv_phandle ).
      CATCH zcx_shk_log INTO DATA(lo_err2).
        WRITE: / |Persistent save error: { lo_err2->get_text( ) }|.
        WRITE: / 'SLG0 object not found. Define it in SLG0 first.'.
    ENDTRY.
  ENDIF.

  " ============================================================
  " 3) show_by_log — save + display in one call
  " ============================================================
  DATA(lo_log3) = NEW zcl_shk_log( iv_extnumber = 'SHOW_BY_LOG' ).
  lo_log3->zif_shk_log~add_free_text( 'show_by_log demo' ).
  lo_log3->zif_shk_log~add_free_text( iv_text = 'Combines save + display' iv_type = 'S' ).
  TRY.
      zcl_shk_log_gui=>show_by_log( lo_log3 ).
    CATCH zcx_shk_log INTO DATA(lo_err3).
      WRITE: / |show_by_log error: { lo_err3->get_text( ) }|.
  ENDTRY.

  " clear
  lo_log->zif_shk_log~clear( ).
  WRITE: / |After clear, count: { lo_log->zif_shk_log~get_count( ) }|.
