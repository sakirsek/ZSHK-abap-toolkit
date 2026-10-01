class ZCL_SHK_FTP definition
  public
  create public .

public section.

  interfaces ZIF_SHK_FTP .

  methods CONSTRUCTOR
    importing
      !IV_HOST type CLIKE
      !IV_USER type CLIKE
      !IV_PASSWORD type CLIKE
      !IV_PORT type I default 21
      !IV_PASSIVE type ABAP_BOOL default ABAP_TRUE .
    "! Parses raw FTP listing lines (dir/ls output) into files.
    "! Skips FTP reply lines (150/226 ...), 'total n', directories, '.'/'..'.
    "! Understands Unix long, Windows/IIS long and plain name (NLST) lines.
  class-methods PARSE_LISTING
    importing
      !IT_LINES type STRING_TABLE
      !IV_MASK type CLIKE default '*'
    returning
      value(RT_FILES) type ZIF_SHK_FTP=>TY_T_FILE .
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_host      TYPE string.
    DATA mv_user      TYPE string.
    DATA mv_password  TYPE string.
    DATA mv_port      TYPE i.
    DATA mv_handle    TYPE i.
    DATA mv_connected TYPE abap_bool.
    DATA mv_passive   TYPE abap_bool.

    METHODS run_command
      IMPORTING
        iv_command       TYPE clike
      RETURNING
        VALUE(rt_result) TYPE string_table
      RAISING
        zcx_shk_ftp.

    METHODS run_command_raw
      IMPORTING
        iv_command       TYPE clike
      RETURNING
        VALUE(rt_result) TYPE string_table
      RAISING
        zcx_shk_ftp.
ENDCLASS.



CLASS ZCL_SHK_FTP IMPLEMENTATION.


  METHOD constructor.
    mv_host      = iv_host.
    mv_user      = iv_user.
    mv_password  = iv_password.
    mv_port      = iv_port.
    mv_passive   = iv_passive.
    mv_connected = abap_false.
  ENDMETHOD.


  METHOD parse_listing.
    CONSTANTS lc_unix TYPE string
      VALUE `^([-dlbcps])[-rwxsStT]{9}\S*\s+\d+\s+\S+\s+(?:\S+\s+)?(\d+)\s+([A-Za-z]{3}\s+\d{1,2}\s+(?:\d{1,2}:\d{2}|\d{4}))\s(.+)$`.
    CONSTANTS lc_windows TYPE string
      VALUE `^(\d{2}-\d{2}-\d{2,4}\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)\s+(<DIR>|\d+)\s+(.+)$`.

    DATA lv_type TYPE string.
    DATA lv_size TYPE string.

    DATA(lv_mask) = to_upper( condense( CONV string( iv_mask ) ) ).
    IF lv_mask IS INITIAL.
      lv_mask = `*`.
    ENDIF.

    LOOP AT it_lines INTO DATA(lv_line).
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN lv_line WITH ``.
      lv_line = shift_right( val = shift_left( val = lv_line sub = ` ` ) sub = ` ` ).

      IF lv_line IS INITIAL
         OR matches( val = lv_line regex = `\d{3}([ -].*)?` )
         OR matches( val = lv_line regex = `total\s+\d+` case = abap_false )
         OR matches( val = lv_line regex = `ftp>.*` case = abap_false ).
        CONTINUE.
      ENDIF.

      DATA(ls_file) = VALUE zif_shk_ftp=>ty_s_file( ).
      CLEAR: lv_type, lv_size.

      FIND REGEX lc_unix IN lv_line SUBMATCHES lv_type lv_size ls_file-date ls_file-name.
      IF sy-subrc = 0.
        IF lv_type <> `-`.
          CONTINUE.
        ENDIF.
      ELSE.
        FIND REGEX lc_windows IN lv_line IGNORING CASE SUBMATCHES ls_file-date lv_size ls_file-name.
        IF sy-subrc = 0.
          IF to_upper( lv_size ) = `<DIR>`.
            CONTINUE.
          ENDIF.
        ELSEIF matches( val = lv_line regex = `\S+` ).
          " a bare name (NLST) has no blanks; SAPFTP's command echo ('dir .')
          " and client notes ('Passive mode: Connected to Port ...') do
          SPLIT lv_line AT `/` INTO TABLE DATA(lt_parts).
          ls_file-name = VALUE #( lt_parts[ lines( lt_parts ) ] OPTIONAL ).
        ELSE.
          CONTINUE.
        ENDIF.
      ENDIF.

      IF ls_file-name IS INITIAL OR ls_file-name = `.` OR ls_file-name = `..`.
        CONTINUE.
      ENDIF.

      TRY.
          ls_file-size = COND #( WHEN lv_size CO `0123456789` AND lv_size IS NOT INITIAL THEN lv_size ).
        CATCH cx_sy_conversion_error.
          ls_file-size = 0.
      ENDTRY.

      IF to_upper( ls_file-name ) CP lv_mask.
        APPEND ls_file TO rt_files.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD run_command.
    LOOP AT run_command_raw( iv_command ) INTO DATA(lv_line).
      DATA(lv_str) = condense( lv_line ).
      IF lv_str IS NOT INITIAL.
        APPEND lv_str TO rt_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD run_command_raw.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected'.
    ENDIF.

    TYPES ty_line(1024) TYPE c.
    DATA lt_raw TYPE STANDARD TABLE OF ty_line.

    CALL FUNCTION 'FTP_COMMAND'
      EXPORTING
        handle        = mv_handle
        command       = CONV char200( iv_command )
      TABLES
        data          = lt_raw
      EXCEPTIONS
        tcpip_error   = 1
        command_error = 2
        data_error    = 3
        OTHERS        = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP command failed: { iv_command }|.
    ENDIF.

    rt_result = VALUE #( FOR lv_raw IN lt_raw ( CONV string( lv_raw ) ) ).
  ENDMETHOD.


  METHOD zif_shk_ftp~cd.
    run_command( |cd { iv_directory }| ).
  ENDMETHOD.


  METHOD zif_shk_ftp~command.
    rt_result = run_command( iv_command ).
  ENDMETHOD.


  METHOD zif_shk_ftp~connect.
    IF mv_connected = abap_true.
      RETURN.
    ENDIF.

    DATA lv_pwd_scrambled TYPE c LENGTH 256.
    DATA lv_pwd TYPE c LENGTH 256.
    lv_pwd = mv_password.

    CALL FUNCTION 'HTTP_SCRAMBLE'
      EXPORTING
        source      = lv_pwd
        sourcelen   = strlen( mv_password )
        key         = 26101957
      IMPORTING
        destination = lv_pwd_scrambled.

    CALL FUNCTION 'FTP_CONNECT'
      EXPORTING
        user            = CONV rfcalias( mv_user )
        password        = lv_pwd_scrambled
        host            = CONV rfcdest( mv_host )
        rfc_destination = 'SAPFTPA'
      IMPORTING
        handle          = mv_handle
      EXCEPTIONS
        not_connected   = 1
        OTHERS          = 2.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP connection failed to { mv_host }: { sy-msgv1 }|.
    ENDIF.

    mv_connected = abap_true.

    " Many FTP servers (e.g. the NURSAN targets) reject active-mode (PORT)
    " data connections, so every dir/STOR fails with command_error while the
    " login itself succeeds. SAPFTP/SAPFTPA default to active mode; switch to
    " passive right after connect unless the caller opted out (iv_passive).
    " Best-effort: a server that ignores the command keeps its default mode.
    IF mv_passive = abap_true.
      TRY.
          zif_shk_ftp~set_passive( abap_true ).
        CATCH zcx_shk_ftp.
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD zif_shk_ftp~delete_file.
    run_command( |delete { iv_remote_path }| ).
  ENDMETHOD.


  METHOD zif_shk_ftp~disconnect.
    IF mv_connected = abap_false.
      RETURN.
    ENDIF.

    CALL FUNCTION 'FTP_DISCONNECT'
      EXPORTING
        handle = mv_handle.

    mv_connected = abap_false.
  ENDMETHOD.


  METHOD zif_shk_ftp~download.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected'.
    ENDIF.

    DATA lt_data TYPE STANDARD TABLE OF raw255.
    DATA lv_len  TYPE i.

    CALL FUNCTION 'FTP_SERVER_TO_R3'
      EXPORTING
        handle         = mv_handle
        fname          = CONV char200( iv_remote_path )
      IMPORTING
        blob_length    = lv_len
      TABLES
        blob           = lt_data
      EXCEPTIONS
        tcpip_error    = 1
        command_error  = 2
        data_error     = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP download failed: { iv_remote_path }|.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_len
      IMPORTING
        buffer       = rv_content
      TABLES
        binary_tab   = lt_data
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
  ENDMETHOD.


  METHOD zif_shk_ftp~download_text.
    DATA(lv_xstring) = zif_shk_ftp~download( iv_remote_path ).

    DATA lv_text TYPE string.
    DATA lo_conv TYPE REF TO cl_abap_conv_in_ce.
    lo_conv = cl_abap_conv_in_ce=>create( encoding = iv_encoding input = lv_xstring ).
    lo_conv->read( IMPORTING data = lv_text ).

    SPLIT lv_text AT cl_abap_char_utilities=>cr_lf INTO TABLE rt_lines.
    IF lines( rt_lines ) <= 1.
      SPLIT lv_text AT cl_abap_char_utilities=>newline INTO TABLE rt_lines.
    ENDIF.

    DELETE rt_lines WHERE table_line IS INITIAL.
  ENDMETHOD.


  METHOD zif_shk_ftp~file_exists.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected'.
    ENDIF.

    TYPES ty_line(1024) TYPE c.
    DATA lt_result TYPE STANDARD TABLE OF ty_line.

    CALL FUNCTION 'FTP_COMMAND'
      EXPORTING
        handle        = mv_handle
        command       = CONV char200( |ls { iv_remote_path }| )
      TABLES
        data          = lt_result
      EXCEPTIONS
        tcpip_error   = 1
        command_error = 2
        data_error    = 3
        OTHERS        = 4.

    rv_exists = xsdbool( sy-subrc = 0 AND lt_result IS NOT INITIAL ).
  ENDMETHOD.


  METHOD zif_shk_ftp~is_connected.
    rv_connected = mv_connected.
  ENDMETHOD.


  METHOD zif_shk_ftp~list_directory.
    DATA(lt_raw) = run_command( |ls { iv_directory }| ).

    LOOP AT lt_raw INTO DATA(lv_line).
      APPEND VALUE zif_shk_ftp=>ty_s_file( name = lv_line ) TO rt_files.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_shk_ftp~list_files.
    " 'dir' asks for the long listing (size/date); servers or SAPFTP builds
    " that refuse it still answer 'ls', which parse_listing also understands.
    DATA lt_lines TYPE string_table.
    TRY.
        lt_lines = run_command_raw( |dir { iv_directory }| ).
      CATCH zcx_shk_ftp.
        lt_lines = run_command_raw( |ls { iv_directory }| ).
    ENDTRY.

    rt_files = parse_listing( it_lines = lt_lines
                              iv_mask  = iv_mask ).
  ENDMETHOD.


  METHOD zif_shk_ftp~rename_file.
    run_command( |rename { iv_from } { iv_to }| ).
  ENDMETHOD.


  METHOD zif_shk_ftp~set_passive.
    IF iv_on = abap_true.
      run_command( 'set passive on' ).
    ELSE.
      run_command( 'set passive off' ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_shk_ftp~upload.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected'.
    ENDIF.

    IF iv_overwrite = abap_false.
      IF zif_shk_ftp~file_exists( iv_remote_path ).
        RAISE EXCEPTION TYPE zcx_shk_ftp
          EXPORTING iv_text = |File already exists: { iv_remote_path }|.
      ENDIF.
    ENDIF.

    DATA lt_data TYPE STANDARD TABLE OF raw255.
    DATA lv_len  TYPE i.
    lv_len = xstrlen( iv_content ).

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = iv_content
      TABLES
        binary_tab = lt_data.

    CALL FUNCTION 'FTP_R3_TO_SERVER'
      EXPORTING
        handle         = mv_handle
        fname          = CONV char200( iv_remote_path )
        blob_length    = lv_len
      TABLES
        blob           = lt_data
      EXCEPTIONS
        tcpip_error    = 1
        command_error  = 2
        data_error     = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP upload failed: { iv_remote_path }|.
    ENDIF.
  ENDMETHOD.


  METHOD zif_shk_ftp~upload_text.
    DATA lv_xstring TYPE xstring.
    DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
    lo_conv = cl_abap_conv_out_ce=>create( encoding = iv_encoding ).
    lo_conv->convert( EXPORTING data = iv_text IMPORTING buffer = lv_xstring ).
    zif_shk_ftp~upload(
      iv_remote_path = iv_remote_path
      iv_content     = lv_xstring
      iv_overwrite   = iv_overwrite ).
  ENDMETHOD.
ENDCLASS.
