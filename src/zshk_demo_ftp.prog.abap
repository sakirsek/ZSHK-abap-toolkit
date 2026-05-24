*&---------------------------------------------------------------------*
*& ZSHK_DEMO_FTP — FTP module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_ftp.

PARAMETERS p_host TYPE text128 DEFAULT '10.249.33.61'.
PARAMETERS p_user TYPE text50.
PARAMETERS p_pwd  TYPE text50.
PARAMETERS p_port TYPE i DEFAULT 21.
PARAMETERS p_dir  TYPE text255 DEFAULT 'MALHOTRA/IN'.
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
      WRITE: / 'is_connected:', lo_ftp->zif_shk_ftp~is_connected( ).

      " set_passive
      lo_ftp->zif_shk_ftp~set_passive( abap_true ).
      WRITE: / 'set_passive: ON'.

      " cd
      lo_ftp->zif_shk_ftp~cd( p_dir ).
      WRITE: / 'cd:', p_dir.
      ULINE.

      " list_directory
      WRITE: / 'Directory listing (current):'.
      DATA(lt_files) = lo_ftp->zif_shk_ftp~list_directory( '.' ).
      LOOP AT lt_files INTO DATA(ls_file).
        WRITE: / '  ', ls_file-name.
      ENDLOOP.
      WRITE: / 'Total:', lines( lt_files ), 'entries'.
      ULINE.

      " file_exists
      DATA(lv_chk) = 'zshk_demo_text.txt'.
      WRITE: / 'file_exists:', lv_chk, lo_ftp->zif_shk_ftp~file_exists( lv_chk ).
      ULINE.

      " upload
      IF p_upl = abap_true.
        DATA lv_overwrite TYPE abap_bool.
        IF p_noov = abap_true.
          lv_overwrite = abap_false.
        ELSE.
          lv_overwrite = abap_true.
        ENDIF.

        " upload_text
        DATA(lv_text) = |ZSHK FTP Demo - { sy-datum } { sy-uzeit }| &&
          cl_abap_char_utilities=>cr_lf &&
          |User: { sy-uname }|.
        lo_ftp->zif_shk_ftp~upload_text(
          iv_remote_path = 'zshk_demo_text.txt'
          iv_text        = lv_text
          iv_encoding    = '4110'
          iv_overwrite   = lv_overwrite ).
        WRITE: / 'upload_text: zshk_demo_text.txt'.

        " upload binary
        DATA lv_bin TYPE xstring.
        DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
        lo_conv = cl_abap_conv_out_ce=>create( encoding = '4110' ).
        lo_conv->convert(
          EXPORTING data = 'Binary upload demo content'
          IMPORTING buffer = lv_bin ).
        lo_ftp->zif_shk_ftp~upload(
          iv_remote_path = 'zshk_demo_bin.dat'
          iv_content     = lv_bin
          iv_overwrite   = lv_overwrite ).
        WRITE: / 'upload (binary): zshk_demo_bin.dat'.
      ENDIF.

      " download (binary)
      IF p_down IS NOT INITIAL.
        DATA(lv_content) = lo_ftp->zif_shk_ftp~download( p_down ).
        WRITE: / 'download:', p_down, xstrlen( lv_content ), 'bytes'.
      ENDIF.

      " download_text
      IF p_upl = abap_true.
        DATA(lt_lines) = lo_ftp->zif_shk_ftp~download_text( 'zshk_demo_text.txt' ).
        WRITE: / 'download_text: zshk_demo_text.txt'.
        LOOP AT lt_lines INTO DATA(lv_line).
          WRITE: / '  >', lv_line.
        ENDLOOP.
      ENDIF.

      " rename_file
      IF p_upl = abap_true.
        lo_ftp->zif_shk_ftp~rename_file(
          iv_from = 'zshk_demo_text.txt'
          iv_to   = 'zshk_demo_renamed.txt' ).
        WRITE: / 'rename_file: text.txt -> renamed.txt'.
      ENDIF.

      " delete_file
      IF p_del = abap_true AND p_upl = abap_true.
        lo_ftp->zif_shk_ftp~delete_file( 'zshk_demo_bin.dat' ).
        WRITE: / 'delete_file: zshk_demo_bin.dat'.
        lo_ftp->zif_shk_ftp~delete_file( 'zshk_demo_renamed.txt' ).
        WRITE: / 'delete_file: zshk_demo_renamed.txt'.
      ENDIF.

      " command (raw FTP command)
      DATA(lt_pwd) = lo_ftp->zif_shk_ftp~command( 'pwd' ).
      WRITE: / 'command(pwd):'.
      LOOP AT lt_pwd INTO DATA(lv_pwd_line).
        WRITE: / '  ', lv_pwd_line.
      ENDLOOP.

      ULINE.

      " disconnect
      lo_ftp->zif_shk_ftp~disconnect( ).
      WRITE: / 'Disconnected'.

    CATCH zcx_shk_ftp INTO DATA(lo_err).
      WRITE: / 'FTP error:', lo_err->get_text( ).
  ENDTRY.
