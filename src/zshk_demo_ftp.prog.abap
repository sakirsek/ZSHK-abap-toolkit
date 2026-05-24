*&---------------------------------------------------------------------*
*& ZSHK_DEMO_FTP — FTP module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_ftp.

PARAMETERS p_host TYPE text128 DEFAULT '10.249.33.61'.
PARAMETERS p_user TYPE text50.
PARAMETERS p_pwd  TYPE text50.
PARAMETERS p_port TYPE i DEFAULT 21.
PARAMETERS p_dir  TYPE text255 DEFAULT '.'.
PARAMETERS p_upl  TYPE abap_bool AS CHECKBOX.
PARAMETERS p_down TYPE text255.

START-OF-SELECTION.

  DATA(lo_ftp) = NEW zcl_shk_ftp(
    iv_host     = p_host
    iv_user     = p_user
    iv_password = p_pwd
    iv_port     = p_port ).

  TRY.
      " connect
      lo_ftp->zif_shk_ftp~connect( ).
      WRITE: / |Connected to { p_host }:{ p_port }|.

      " is_connected
      DATA(lv_conn) = lo_ftp->zif_shk_ftp~is_connected( ).
      WRITE: / |Connected: { lv_conn }|.
      ULINE.

      " list_directory
      WRITE: / |Directory listing: { p_dir }|.
      DATA(lt_files) = lo_ftp->zif_shk_ftp~list_directory( p_dir ).
      LOOP AT lt_files INTO DATA(ls_file).
        WRITE: / |  { ls_file-name }|.
      ENDLOOP.
      WRITE: / |Total: { lines( lt_files ) } entries|.
      ULINE.

      " upload_text
      IF p_upl = abap_true.
        DATA(lv_text) = |ZSHK FTP Demo - { sy-datum } { sy-uzeit }| &&
          cl_abap_char_utilities=>cr_lf &&
          |User: { sy-uname }|.
        lo_ftp->zif_shk_ftp~upload_text(
          iv_remote_path = '/zshk_demo_test.txt'
          iv_text        = lv_text ).
        WRITE: / 'Uploaded: /zshk_demo_test.txt'.
      ENDIF.

      " download
      IF p_down IS NOT INITIAL.
        DATA(lv_content) = lo_ftp->zif_shk_ftp~download( p_down ).
        WRITE: / |Downloaded: { p_down } ({ xstrlen( lv_content ) } bytes)|.
      ENDIF.

      " disconnect
      lo_ftp->zif_shk_ftp~disconnect( ).
      WRITE: / 'Disconnected'.

    CATCH zcx_shk_ftp INTO DATA(lo_err).
      WRITE: / 'FTP error:', lo_err->get_text( ).
  ENDTRY.
