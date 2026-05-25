CLASS zcl_shk_log_gui DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS show_by_handle
      IMPORTING
        iv_log_handle TYPE balloghndl
      RAISING
        zcx_shk_log.

    CLASS-METHODS show_by_messages
      IMPORTING
        it_messages TYPE zif_shk_log=>ty_t_msg
        iv_title    TYPE baltitle DEFAULT 'Log'.

    CLASS-METHODS show_by_log
      IMPORTING
        io_log TYPE REF TO zif_shk_log
      RAISING
        zcx_shk_log.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shk_log_gui IMPLEMENTATION.
  METHOD show_by_handle.
    DATA lt_handles TYPE bal_t_logh.
    APPEND iv_log_handle TO lt_handles.

    DATA ls_profile TYPE bal_s_prof.
    CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
      IMPORTING
        e_s_display_profile = ls_profile
      EXCEPTIONS
        OTHERS              = 1.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_log
        EXPORTING iv_text = 'BAL_DSP_PROFILE_POPUP_GET failed'.
    ENDIF.

    ls_profile-use_grid = abap_true.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile = ls_profile
        i_t_log_handle      = lt_handles
      EXCEPTIONS
        profile_inconsistent = 1
        internal_error       = 2
        no_data_available    = 3
        no_authority         = 4
        OTHERS               = 5.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_log
        EXPORTING iv_text = |BAL_DSP_LOG_DISPLAY failed: { sy-msgv1 }|.
    ENDIF.
  ENDMETHOD.

  METHOD show_by_messages.
    DATA ls_msg TYPE bal_s_msg.

    DATA ls_header TYPE bal_s_log.
    ls_header-extnumber = iv_title.
    ls_header-aldate    = sy-datum.
    ls_header-altime    = sy-uzeit.
    ls_header-aluser    = sy-uname.

    DATA lv_handle TYPE balloghndl.

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = ls_header
      IMPORTING
        e_log_handle = lv_handle
      EXCEPTIONS
        OTHERS       = 1.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT it_messages INTO DATA(ls_in).
      CLEAR ls_msg.
      ls_msg-msgty = ls_in-type.
      ls_msg-msgid = ls_in-id.
      ls_msg-msgno = ls_in-number.
      ls_msg-msgv1 = ls_in-v1.
      ls_msg-msgv2 = ls_in-v2.
      ls_msg-msgv3 = ls_in-v3.
      ls_msg-msgv4 = ls_in-v4.

      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_log_handle = lv_handle
          i_s_msg      = ls_msg
        EXCEPTIONS
          OTHERS       = 1.
    ENDLOOP.

    DATA lt_handles TYPE bal_t_logh.
    APPEND lv_handle TO lt_handles.

    DATA ls_profile TYPE bal_s_prof.
    CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
      IMPORTING
        e_s_display_profile = ls_profile
      EXCEPTIONS
        OTHERS              = 1.

    ls_profile-use_grid = abap_true.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile = ls_profile
        i_t_log_handle      = lt_handles
      EXCEPTIONS
        OTHERS              = 1.
  ENDMETHOD.

  METHOD show_by_log.
    DATA(lv_handle) = io_log->save( ).
    show_by_handle( lv_handle ).
  ENDMETHOD.
ENDCLASS.
