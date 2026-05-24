*&---------------------------------------------------------------------*
*& ZSHK_DEMO_MAIL — Mail module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_mail.

PARAMETERS p_to   TYPE ad_smtpadr.
PARAMETERS p_cc   TYPE ad_smtpadr.
PARAMETERS p_bcc  TYPE ad_smtpadr.
PARAMETERS p_from TYPE ad_smtpadr.
PARAMETERS p_subj TYPE so_obj_des DEFAULT 'ZSHK Mail Test'.
PARAMETERS p_html TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_att  TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_tabl TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_send TYPE abap_bool AS CHECKBOX.

TYPES:
  BEGIN OF ty_demo_row,
    matnr TYPE matnr,
    maktx TYPE maktx,
    meins TYPE meins,
  END OF ty_demo_row.

START-OF-SELECTION.

  DATA(lo_mail) = NEW zcl_shk_mail( ).

  " set_subject
  lo_mail->zif_shk_mail~set_subject( p_subj ).

  " set_body_html / set_body_text
  IF p_html = abap_true.
    DATA(lv_html) = |<html><body>| &&
      |<h2>ZSHK Mail Demo</h2>| &&
      |<p>Bu mail <b>ZCL_SHK_MAIL</b> ile gonderildi.</p>| &&
      |<p>Tarih: { sy-datum DATE = USER } Saat: { sy-uzeit TIME = USER }</p>|.
    lo_mail->zif_shk_mail~set_body_html( lv_html ).
    WRITE: / 'Body: HTML'.
  ELSE.
    lo_mail->zif_shk_mail~set_body_text( 'Bu bir ZSHK Mail test mesajidir.' ).
    WRITE: / 'Body: Plain text'.
  ENDIF.

  " add_table — internal table to HTML table
  IF p_tabl = abap_true.
    DATA lt_demo TYPE STANDARD TABLE OF ty_demo_row.
    lt_demo = VALUE #(
      ( matnr = 'MAT001' maktx = 'Kablo 2.5mm' meins = 'MT' )
      ( matnr = 'MAT002' maktx = 'Terminal Tip A' meins = 'AD' )
      ( matnr = 'MAT003' maktx = 'Conta 10x15' meins = 'AD' ) ).

    " with custom column titles
    DATA lt_cols TYPE zif_shk_mail=>ty_t_column.
    lt_cols = VALUE #(
      ( fieldname = 'MATNR' title = 'Malzeme No' )
      ( fieldname = 'MAKTX' title = 'Tanim' )
      ( fieldname = 'MEINS' title = 'Birim' ) ).

    lo_mail->zif_shk_mail~add_table(
      it_table   = lt_demo
      it_columns = lt_cols
      iv_title   = 'Malzeme Listesi' ).
    WRITE: / 'Table: 3 rows with custom column titles'.

    " second table without custom columns (uses field names as headers)
    lo_mail->zif_shk_mail~add_table( it_table = lt_demo ).
    WRITE: / 'Table: 3 rows with default field name headers'.
  ENDIF.

  " add_recipient — TO
  lo_mail->zif_shk_mail~add_recipient( p_to ).
  WRITE: / 'TO:', p_to.

  " add_recipient — CC
  IF p_cc IS NOT INITIAL.
    lo_mail->zif_shk_mail~add_recipient( iv_address = p_cc iv_copy = 'C' ).
    WRITE: / 'CC:', p_cc.
  ENDIF.

  " add_recipient — BCC
  IF p_bcc IS NOT INITIAL.
    lo_mail->zif_shk_mail~add_recipient( iv_address = p_bcc iv_copy = 'B' ).
    WRITE: / 'BCC:', p_bcc.
  ENDIF.

  " set_sender
  IF p_from IS NOT INITIAL.
    lo_mail->zif_shk_mail~set_sender( p_from ).
    WRITE: / 'From:', p_from.
  ENDIF.

  " set_importance
  lo_mail->zif_shk_mail~set_importance( '1' ).
  WRITE: / 'Importance: High'.

  " add_attachment_csv
  IF p_att = abap_true.
    DATA lv_csv TYPE string.
    lv_csv = |MATNR;MAKTX;MEINS| && cl_abap_char_utilities=>cr_lf &&
             |MAT001;Test Malzeme 1;KG| && cl_abap_char_utilities=>cr_lf &&
             |MAT002;Ornek Malzeme 2;AD| && cl_abap_char_utilities=>cr_lf.
    lo_mail->zif_shk_mail~add_attachment_csv(
      iv_filename = 'test_data.csv'
      iv_csv      = lv_csv ).
    WRITE: / 'Attachment 1: test_data.csv (CSV)'.

    " add_attachment — binary (xstring)
    DATA lv_bin TYPE xstring.
    DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
    lo_conv = cl_abap_conv_out_ce=>create( encoding = '4110' ).
    lo_conv->convert(
      EXPORTING data = 'Binary attachment demo content'
      IMPORTING buffer = lv_bin ).
    lo_mail->zif_shk_mail~add_attachment(
      iv_filename = 'demo_note.txt'
      iv_content  = lv_bin
      iv_mimetype = 'text/plain' ).
    WRITE: / 'Attachment 2: demo_note.txt (binary)'.
  ENDIF.

  ULINE.

  " send
  IF p_send = abap_true.
    TRY.
        lo_mail->zif_shk_mail~send( ).
        WRITE: / 'Mail sent successfully!'.
      CATCH zcx_shk_mail INTO DATA(lo_err).
        WRITE: / 'Send error:', lo_err->get_text( ).
    ENDTRY.
  ELSE.
    WRITE: / 'Check "Send" to actually send the mail'.
  ENDIF.
