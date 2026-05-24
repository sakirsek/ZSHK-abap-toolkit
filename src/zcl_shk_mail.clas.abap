CLASS zcl_shk_mail DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_mail.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_recipient,
        address TYPE adr6-smtp_addr,
        copy    TYPE char1,
      END OF ty_s_recipient.

    DATA mv_subject    TYPE so_obj_des.
    DATA mv_body       TYPE string.
    DATA mv_is_html    TYPE abap_bool.
    DATA mv_sender     TYPE adr6-smtp_addr.
    DATA mv_importance TYPE bcs_docimp VALUE '5'.
    DATA mt_recipients TYPE STANDARD TABLE OF ty_s_recipient WITH EMPTY KEY.
    DATA mt_attachments TYPE zif_shk_mail=>ty_t_attachment.

    METHODS build_document
      RETURNING VALUE(ro_document) TYPE REF TO cl_document_bcs
      RAISING   zcx_shk_mail.

    METHODS render_table_html
      IMPORTING
        it_table         TYPE ANY TABLE
        it_columns       TYPE zif_shk_mail=>ty_t_column OPTIONAL
        iv_title         TYPE clike OPTIONAL
      RETURNING
        VALUE(rv_html)   TYPE string.
ENDCLASS.

CLASS zcl_shk_mail IMPLEMENTATION.
  METHOD zif_shk_mail~set_subject.
    mv_subject = iv_subject.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~set_body_text.
    mv_body    = iv_body.
    mv_is_html = abap_false.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~set_body_html.
    mv_body    = iv_html.
    mv_is_html = abap_true.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~add_table.
    DATA(lv_table_html) = render_table_html(
      it_table   = it_table
      it_columns = it_columns
      iv_title   = iv_title ).

    IF mv_is_html = abap_true AND mv_body IS NOT INITIAL.
      mv_body = mv_body && lv_table_html.
    ELSE.
      mv_body = lv_table_html.
      mv_is_html = abap_true.
    ENDIF.

    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~add_recipient.
    APPEND VALUE ty_s_recipient( address = iv_address copy = iv_copy ) TO mt_recipients.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~add_attachment.
    APPEND VALUE zif_shk_mail=>ty_s_attachment(
      filename = iv_filename
      content  = iv_content
      mimetype = iv_mimetype ) TO mt_attachments.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~add_attachment_csv.
    DATA lv_xstring TYPE xstring.
    DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
    lo_conv = cl_abap_conv_out_ce=>create( encoding = '4110' ).
    lo_conv->convert( EXPORTING data = iv_csv IMPORTING buffer = lv_xstring ).

    APPEND VALUE zif_shk_mail=>ty_s_attachment(
      filename = iv_filename
      content  = lv_xstring
      mimetype = 'text/csv' ) TO mt_attachments.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~set_sender.
    mv_sender = iv_address.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~set_importance.
    mv_importance = iv_importance.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_mail~send.
    IF mt_recipients IS INITIAL.
      RAISE EXCEPTION TYPE zcx_shk_mail
        EXPORTING iv_text = 'No recipients specified'.
    ENDIF.

    TRY.
        DATA(lo_bcs) = cl_bcs=>create_persistent( ).
        DATA(lo_doc) = build_document( ).
        lo_bcs->set_document( lo_doc ).

        LOOP AT mt_recipients INTO DATA(ls_recip).
          DATA(lo_recip) = cl_cam_address_bcs=>create_internet_address( ls_recip-address ).
          IF ls_recip-copy = 'C'.
            lo_bcs->add_recipient( i_recipient = lo_recip i_copy = abap_true ).
          ELSEIF ls_recip-copy = 'B'.
            lo_bcs->add_recipient( i_recipient = lo_recip i_blind_copy = abap_true ).
          ELSE.
            lo_bcs->add_recipient( lo_recip ).
          ENDIF.
        ENDLOOP.

        IF mv_sender IS NOT INITIAL.
          DATA(lo_sender) = cl_cam_address_bcs=>create_internet_address( mv_sender ).
          lo_bcs->set_sender( lo_sender ).
        ENDIF.

        lo_bcs->set_send_immediately( abap_true ).
        lo_bcs->send( ).

        IF iv_commit = abap_true.
          COMMIT WORK.
        ENDIF.

      CATCH cx_bcs INTO DATA(lo_bcs_error).
        RAISE EXCEPTION TYPE zcx_shk_mail
          EXPORTING iv_text  = lo_bcs_error->get_text( )
                    previous = lo_bcs_error.
    ENDTRY.
  ENDMETHOD.

  METHOD build_document.
    TRY.
        IF mv_is_html = abap_true.
          DATA lt_html TYPE soli_tab.
          lt_html = cl_bcs_convert=>string_to_soli( mv_body ).
          ro_document = cl_document_bcs=>create_document(
            i_type    = 'HTM'
            i_text    = lt_html
            i_subject = mv_subject
            i_importance = mv_importance ).
        ELSE.
          DATA lt_text TYPE soli_tab.
          lt_text = cl_bcs_convert=>string_to_soli( mv_body ).
          ro_document = cl_document_bcs=>create_document(
            i_type    = 'RAW'
            i_text    = lt_text
            i_subject = mv_subject
            i_importance = mv_importance ).
        ENDIF.

        LOOP AT mt_attachments INTO DATA(ls_att).
          DATA lt_hex TYPE solix_tab.
          DATA lv_size TYPE sood-objlen.
          lt_hex = cl_bcs_convert=>xstring_to_solix( ls_att-content ).
          lv_size = xstrlen( ls_att-content ).
          ro_document->add_attachment(
            i_attachment_type    = 'BIN'
            i_attachment_subject = CONV #( ls_att-filename )
            i_attachment_size    = lv_size
            i_att_content_hex    = lt_hex ).
        ENDLOOP.

      CATCH cx_bcs INTO DATA(lo_error).
        RAISE EXCEPTION TYPE zcx_shk_mail
          EXPORTING iv_text  = lo_error->get_text( )
                    previous = lo_error.
    ENDTRY.
  ENDMETHOD.

  METHOD render_table_html.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    DATA lo_table TYPE REF TO cl_abap_tabledescr.
    lo_table ?= cl_abap_typedescr=>describe_by_data( it_table ).
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    lo_struct ?= lo_table->get_table_line_type( ).
    DATA(lt_components) = lo_struct->get_components( ).

    IF iv_title IS NOT INITIAL.
      rv_html = |<h3>{ iv_title }</h3>|.
    ENDIF.

    rv_html = rv_html &&
      |<table border="1" cellpadding="4" cellspacing="0" | &&
      |style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:12px">|.

    rv_html = rv_html && '<tr style="background-color:#4472C4;color:#FFFFFF;font-weight:bold">'.
    LOOP AT lt_components INTO DATA(ls_comp).
      DATA lv_header TYPE string.
      CLEAR lv_header.
      IF it_columns IS NOT INITIAL.
        READ TABLE it_columns INTO DATA(ls_col)
          WITH KEY fieldname = ls_comp-name.
        IF sy-subrc = 0.
          lv_header = ls_col-title.
        ENDIF.
      ENDIF.
      IF lv_header IS INITIAL.
        lv_header = ls_comp-name.
      ENDIF.
      rv_html = rv_html && |<td>{ lv_header }</td>|.
    ENDLOOP.
    rv_html = rv_html && '</tr>'.

    DATA lv_row_idx TYPE i.
    LOOP AT it_table ASSIGNING <ls_row>.
      lv_row_idx = sy-tabix MOD 2.
      IF lv_row_idx = 0.
        rv_html = rv_html && '<tr style="background-color:#D9E2F3">'.
      ELSE.
        rv_html = rv_html && '<tr>'.
      ENDIF.
      LOOP AT lt_components INTO ls_comp.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row> TO <lv_field>.
        IF sy-subrc = 0.
          rv_html = rv_html && |<td>{ <lv_field> }</td>|.
        ELSE.
          rv_html = rv_html && '<td></td>'.
        ENDIF.
      ENDLOOP.
      rv_html = rv_html && '</tr>'.
    ENDLOOP.

    rv_html = rv_html && '</table><br>'.
  ENDMETHOD.
ENDCLASS.
