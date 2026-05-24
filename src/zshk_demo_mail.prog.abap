*&---------------------------------------------------------------------*
*& ZSHK_DEMO_MAIL — Mail module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_mail.

PARAMETERS p_to   TYPE ad_smtpadr.
PARAMETERS p_cc   TYPE ad_smtpadr.
PARAMETERS p_subj TYPE so_obj_des DEFAULT 'ZSHK Mail Test'.
PARAMETERS p_html TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_att  TYPE abap_bool AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_send TYPE abap_bool AS CHECKBOX.

START-OF-SELECTION.

  DATA(lo_mail) = NEW zcl_shk_mail( ).

  " set_subject
  lo_mail->zif_shk_mail~set_subject( p_subj ).

  " set_body_html / set_body_text
  IF p_html = abap_true.
    DATA(lv_html) = |<html><body>| &&
      |<h2>ZSHK Mail Demo</h2>| &&
      |<p>Bu mail <b>ZCL_SHK_MAIL</b> ile gonderildi.</p>| &&
      |<table border="1" cellpadding="4">| &&
      |<tr><th>Modul</th><th>Durum</th></tr>| &&
      |<tr><td>Log</td><td>Tamamlandi</td></tr>| &&
      |<tr><td>Mail</td><td>Test ediliyor</td></tr>| &&
      |</table>| &&
      |<p>Tarih: { sy-datum DATE = USER } Saat: { sy-uzeit TIME = USER }</p>| &&
      |</body></html>|.
    lo_mail->zif_shk_mail~set_body_html( lv_html ).
    WRITE: / 'Body: HTML'.
  ELSE.
    lo_mail->zif_shk_mail~set_body_text( 'Bu bir ZSHK Mail test mesajidir.' ).
    WRITE: / 'Body: Plain text'.
  ENDIF.

  " add_recipient (TO)
  lo_mail->zif_shk_mail~add_recipient( p_to ).
  WRITE: / 'TO:', p_to.

  " add_recipient (CC)
  IF p_cc IS NOT INITIAL.
    lo_mail->zif_shk_mail~add_recipient( iv_address = p_cc iv_copy = 'C' ).
    WRITE: / 'CC:', p_cc.
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
    WRITE: / 'Attachment: test_data.csv (CSV)'.
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
