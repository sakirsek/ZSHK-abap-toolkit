CLASS zcl_shk_ftp DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_ftp.

    METHODS constructor
      IMPORTING
        iv_host     TYPE clike
        iv_user     TYPE clike
        iv_password TYPE clike
        iv_port     TYPE i DEFAULT 21.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_host      TYPE string.
    DATA mv_user      TYPE string.
    DATA mv_password  TYPE string.
    DATA mv_port      TYPE i.
    DATA mv_handle    TYPE i.
    DATA mv_connected TYPE abap_bool.
ENDCLASS.

CLASS zcl_shk_ftp IMPLEMENTATION.
  METHOD constructor.
    mv_host      = iv_host.
    mv_user      = iv_user.
    mv_password  = iv_password.
    mv_port      = iv_port.
    mv_connected = abap_false.
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

  METHOD zif_shk_ftp~upload.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected — call connect( ) first'.
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
        EXPORTING iv_text = |FTP upload failed for { iv_remote_path }: { sy-msgv1 }|.
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

  METHOD zif_shk_ftp~download.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected — call connect( ) first'.
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
        EXPORTING iv_text = |FTP download failed for { iv_remote_path }: { sy-msgv1 }|.
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

  METHOD zif_shk_ftp~list_directory.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected — call connect( ) first'.
    ENDIF.

    TYPES ty_line(1024) TYPE c.
    DATA lt_result TYPE STANDARD TABLE OF ty_line.

    CALL FUNCTION 'FTP_COMMAND'
      EXPORTING
        handle        = mv_handle
        command       = CONV char200( |ls { iv_directory }| )
      TABLES
        data          = lt_result
      EXCEPTIONS
        tcpip_error   = 1
        command_error = 2
        data_error    = 3
        OTHERS        = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP list failed for { iv_directory }: { sy-msgv1 }|.
    ENDIF.

    LOOP AT lt_result INTO DATA(lv_line).
      DATA(lv_trimmed) = condense( CONV string( lv_line ) ).
      IF lv_trimmed IS NOT INITIAL.
        APPEND VALUE zif_shk_ftp=>ty_s_file( name = lv_trimmed ) TO rt_files.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_shk_ftp~delete_file.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected — call connect( ) first'.
    ENDIF.

    TYPES ty_line(1024) TYPE c.
    DATA lt_result TYPE STANDARD TABLE OF ty_line.

    CALL FUNCTION 'FTP_COMMAND'
      EXPORTING
        handle        = mv_handle
        command       = CONV char200( |delete { iv_remote_path }| )
      TABLES
        data          = lt_result
      EXCEPTIONS
        tcpip_error   = 1
        command_error = 2
        data_error    = 3
        OTHERS        = 4.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = |FTP delete failed for { iv_remote_path }: { sy-msgv1 }|.
    ENDIF.
  ENDMETHOD.

  METHOD zif_shk_ftp~file_exists.
    IF mv_connected = abap_false.
      RAISE EXCEPTION TYPE zcx_shk_ftp
        EXPORTING iv_text = 'Not connected — call connect( ) first'.
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
ENDCLASS.
