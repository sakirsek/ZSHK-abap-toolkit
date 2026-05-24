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
PARAMETERS p_noov TYPE abap_bool AS CHECKBOX.
PARAMETERS p_del  TYPE abap_bool AS CHECKBOX.
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
      WRITE: / 'Connected to:', p_host.

      " is_connected
      DATA(lv_conn) = lo_ftp->zif_shk_ftp~is_connected( ).
      WRITE: / 'is_connected:', lv_conn.
      ULINE.

      " list_directory
      WRITE: / 'Directory listing:', p_dir.
      DATA(lt_files) = lo_ftp->zif_shk_ftp~list_directory( p_dir ).
      LOOP AT lt_files INTO DATA(ls_file).
        WRITE: / '  ', ls_file-name.
      ENDLOOP.
      WRITE: / 'Total:', lines( lt_files ), 'entries'.
      ULINE.

      " file_exists
      DATA(lv_chk) = '/zshk_demo_text.txt'.
      DATA(lv_exists) = lo_ftp->zif_shk_ftp~file_exists( lv_chk ).
      WRITE: / 'file_exists:', lv_chk, lv_exists.
      ULINE.

      IF p_upl = abap_true.
        DATA lv_overwrite TYPE abap_bool.
        IF p_noov = abap_true.
          lv_overwrite = abap_false.
        ELSE.
          lv_overwrite = abap_true.
        ENDIF.

        " upload_text (with overwrite control)
        DATA(lv_text) = |ZSHK FTP Demo - { sy-datum } { sy-uzeit }| &&
          cl_abap_char_utilities=>cr_lf &&
          |User: { sy-uname }|.
        lo_ftp->zif_shk_ftp~upload_text(
          iv_remote_path = '/zshk_demo_text.txt'
          iv_text        = lv_text
          iv_encoding    = '4110'
          iv_overwrite   = lv_overwrite ).
        WRITE: / 'upload_text: /zshk_demo_text.txt'.

        " upload binary (with overwrite control)
        DATA lv_bin TYPE xstring.
        DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
        lo_conv = cl_abap_conv_out_ce=>create( encoding = '4110' ).
        lo_conv->convert(
          EXPORTING data = 'Binary upload demo content'
          IMPORTING buffer = lv_bin ).
        lo_ftp->zif_shk_ftp~upload(
          iv_remote_path = '/zshk_demo_bin.dat'
          iv_content     = lv_bin
          iv_overwrite   = lv_overwrite ).
        WRITE: / 'upload (binary): /zshk_demo_bin.dat'.
      ENDIF.

      " download
      IF p_down IS NOT INITIAL.
        DATA(lv_content) = lo_ftp->zif_shk_ftp~download( p_down ).
        DATA lv_size TYPE i.
        lv_size = xstrlen( lv_content ).
        WRITE: / 'Downloaded:', p_down, lv_size, 'bytes'.
      ENDIF.

      " delete_file
      IF p_del = abap_true AND p_upl = abap_true.
        lo_ftp->zif_shk_ftp~delete_file( '/zshk_demo_bin.dat' ).
        WRITE: / 'delete_file: /zshk_demo_bin.dat'.
      ENDIF.

      ULINE.

      " disconnect
      lo_ftp->zif_shk_ftp~disconnect( ).
      WRITE: / 'Disconnected'.

    CATCH zcx_shk_ftp INTO DATA(lo_err).
      WRITE: / 'FTP error:', lo_err->get_text( ).
  ENDTRY.
