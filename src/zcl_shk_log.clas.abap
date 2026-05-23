CLASS zcl_shk_log DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_log.

    METHODS constructor
      IMPORTING
        iv_object    TYPE balobj_d DEFAULT 'APPL_LOG'
        iv_subobject TYPE balsubobj  DEFAULT space
        iv_extnumber TYPE balnrext   OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_log_handle TYPE balloghndl.
    DATA mt_messages   TYPE zif_shk_log=>ty_t_msg.
    DATA mv_object     TYPE balobj_d.
    DATA mv_subobject  TYPE balsubobj.
    DATA mv_extnumber  TYPE balnrext.
    DATA mv_created    TYPE abap_bool.

    METHODS ensure_log_created
      RAISING zcx_shk_log.

    METHODS append_msg
      IMPORTING
        iv_type   TYPE symsgty
        iv_id     TYPE symsgid DEFAULT 'ZSHK_MSG'
        iv_number TYPE symsgno DEFAULT '001'
        iv_v1     TYPE symsgv  DEFAULT space
        iv_v2     TYPE symsgv  DEFAULT space
        iv_v3     TYPE symsgv  DEFAULT space
        iv_v4     TYPE symsgv  DEFAULT space
        iv_text   TYPE bapi_msg DEFAULT space.
ENDCLASS.

CLASS zcl_shk_log IMPLEMENTATION.
  METHOD constructor.
    mv_object    = iv_object.
    mv_subobject = iv_subobject.
    mv_extnumber = iv_extnumber.
    mv_created   = abap_false.
  ENDMETHOD.

  METHOD ensure_log_created.
    IF mv_created = abap_true.
      RETURN.
    ENDIF.

    DATA ls_header TYPE bal_s_log.
    ls_header-object    = mv_object.
    ls_header-subobject = mv_subobject.
    ls_header-extnumber = mv_extnumber.
    ls_header-aldate    = sy-datum.
    ls_header-altime    = sy-uzeit.
    ls_header-aluser    = sy-uname.

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = ls_header
      IMPORTING
        e_log_handle            = mv_log_handle
      EXCEPTIONS
        log_header_inconsistent = 1
        OTHERS                  = 2.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_log
        EXPORTING iv_text = |BAL_LOG_CREATE failed: { sy-msgv1 }|.
    ENDIF.

    mv_created = abap_true.
  ENDMETHOD.

  METHOD append_msg.
    DATA ls_msg TYPE zif_shk_log=>ty_s_msg.
    ls_msg-type    = iv_type.
    ls_msg-id      = iv_id.
    ls_msg-number  = iv_number.
    ls_msg-message = iv_text.
    ls_msg-v1      = iv_v1.
    ls_msg-v2      = iv_v2.
    ls_msg-v3      = iv_v3.
    ls_msg-v4      = iv_v4.
    APPEND ls_msg TO mt_messages.
  ENDMETHOD.

  METHOD zif_shk_log~add_free_text.
    append_msg(
      iv_type = iv_type
      iv_v1   = CONV #( iv_text )
      iv_text = CONV #( iv_text ) ).
  ENDMETHOD.

  METHOD zif_shk_log~add_bapiret2.
    append_msg(
      iv_type   = COND #( WHEN is_return-type IS NOT INITIAL THEN is_return-type ELSE 'I' )
      iv_id     = COND #( WHEN is_return-id IS NOT INITIAL THEN is_return-id ELSE 'ZSHK_MSG' )
      iv_number = COND #( WHEN is_return-number IS NOT INITIAL THEN is_return-number ELSE '001' )
      iv_v1     = is_return-message_v1
      iv_v2     = is_return-message_v2
      iv_v3     = is_return-message_v3
      iv_v4     = is_return-message_v4
      iv_text   = is_return-message ).
  ENDMETHOD.

  METHOD zif_shk_log~add_bapiret2_table.
    LOOP AT it_return INTO DATA(ls_return).
      zif_shk_log~add_bapiret2( ls_return ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_shk_log~add_sy_msg.
    append_msg(
      iv_type   = iv_type
      iv_id     = iv_id
      iv_number = iv_no
      iv_v1     = iv_v1
      iv_v2     = iv_v2
      iv_v3     = iv_v3
      iv_v4     = iv_v4 ).
  ENDMETHOD.

  METHOD zif_shk_log~add_exception.
    DATA lv_text TYPE string.
    lv_text = io_exception->get_text( ).
    append_msg(
      iv_type = iv_type
      iv_v1   = CONV #( lv_text )
      iv_text = CONV #( lv_text ) ).
  ENDMETHOD.

  METHOD zif_shk_log~save.
    ensure_log_created( ).

    DATA ls_bal_msg TYPE bal_s_msg.

    LOOP AT mt_messages INTO DATA(ls_msg).
      CLEAR ls_bal_msg.
      ls_bal_msg-msgty = ls_msg-type.
      ls_bal_msg-msgid = ls_msg-id.
      ls_bal_msg-msgno = ls_msg-number.
      ls_bal_msg-msgv1 = ls_msg-v1.
      ls_bal_msg-msgv2 = ls_msg-v2.
      ls_bal_msg-msgv3 = ls_msg-v3.
      ls_bal_msg-msgv4 = ls_msg-v4.

      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_log_handle     = mv_log_handle
          i_s_msg          = ls_bal_msg
        EXCEPTIONS
          log_not_found    = 1
          msg_inconsistent = 2
          log_is_full      = 3
          OTHERS           = 4.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_shk_log
          EXPORTING iv_text = |BAL_LOG_MSG_ADD failed for message { sy-tabix }|.
      ENDIF.
    ENDLOOP.

    DATA lt_handles TYPE bal_t_logh.
    APPEND mv_log_handle TO lt_handles.

    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_t_log_handle   = lt_handles
      EXCEPTIONS
        log_not_found    = 1
        save_not_allowed = 2
        numbering_error  = 3
        OTHERS           = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_log
        EXPORTING iv_text = |BAL_DB_SAVE failed: { sy-msgv1 }|.
    ENDIF.

    rv_log_handle = mv_log_handle.
  ENDMETHOD.

  METHOD zif_shk_log~get_messages.
    rt_messages = mt_messages.
  ENDMETHOD.

  METHOD zif_shk_log~has_errors.
    rv_has_errors = xsdbool( line_exists( mt_messages[ type = 'E' ] )
                          OR line_exists( mt_messages[ type = 'A' ] ) ).
  ENDMETHOD.

  METHOD zif_shk_log~get_count.
    rv_count = lines( mt_messages ).
  ENDMETHOD.

  METHOD zif_shk_log~clear.
    CLEAR mt_messages.
  ENDMETHOD.
ENDCLASS.
