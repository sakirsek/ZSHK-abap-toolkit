CLASS zcl_shk_bdc DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_bdc.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mt_bdcdata TYPE tab_bdcdata.
ENDCLASS.

CLASS zcl_shk_bdc IMPLEMENTATION.
  METHOD zif_shk_bdc~add_screen.
    DATA ls_bdc TYPE bdcdata.
    ls_bdc-program  = iv_program.
    ls_bdc-dynpro   = iv_dynpro.
    ls_bdc-dynbegin = abap_true.
    APPEND ls_bdc TO mt_bdcdata.
  ENDMETHOD.

  METHOD zif_shk_bdc~add_field.
    DATA ls_bdc TYPE bdcdata.
    ls_bdc-fnam  = iv_name.
    ls_bdc-fval  = iv_value.
    APPEND ls_bdc TO mt_bdcdata.
  ENDMETHOD.

  METHOD zif_shk_bdc~add_okcode.
    DATA ls_bdc TYPE bdcdata.
    ls_bdc-fnam = 'BDC_OKCODE'.
    ls_bdc-fval = iv_okcode.
    APPEND ls_bdc TO mt_bdcdata.
  ENDMETHOD.

  METHOD zif_shk_bdc~execute.
    IF mt_bdcdata IS INITIAL.
      RAISE EXCEPTION TYPE zcx_shk_bdc
        EXPORTING iv_text = 'BDC data is empty — add screens/fields first'.
    ENDIF.

    DATA ls_options TYPE ctu_params.
    ls_options-dismode = iv_dismode.
    ls_options-updmode = iv_updmode.
    ls_options-defsize = abap_true.

    DATA lt_msgtab TYPE tab_bdcmsgcoll.

    CALL TRANSACTION iv_tcode
      USING mt_bdcdata
      OPTIONS FROM ls_options
      MESSAGES INTO lt_msgtab.

    LOOP AT lt_msgtab INTO DATA(ls_msg).
      DATA ls_return TYPE bapiret2.
      CLEAR ls_return.
      ls_return-type       = ls_msg-msgtyp.
      ls_return-id         = ls_msg-msgid.
      ls_return-number     = ls_msg-msgnr.
      ls_return-message_v1 = ls_msg-msgv1.
      ls_return-message_v2 = ls_msg-msgv2.
      ls_return-message_v3 = ls_msg-msgv3.
      ls_return-message_v4 = ls_msg-msgv4.

      MESSAGE ID ls_msg-msgid TYPE 'I' NUMBER ls_msg-msgnr
        WITH ls_msg-msgv1 ls_msg-msgv2 ls_msg-msgv3 ls_msg-msgv4
        INTO ls_return-message.

      APPEND ls_return TO rt_messages.
    ENDLOOP.

    zif_shk_bdc~clear( ).
  ENDMETHOD.

  METHOD zif_shk_bdc~get_bdcdata.
    rt_bdcdata = mt_bdcdata.
  ENDMETHOD.

  METHOD zif_shk_bdc~clear.
    CLEAR mt_bdcdata.
  ENDMETHOD.
ENDCLASS.
