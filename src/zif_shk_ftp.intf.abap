INTERFACE zif_shk_ftp PUBLIC.

  TYPES:
    BEGIN OF ty_s_file,
      name TYPE string,
      size TYPE i,
      date TYPE string,
    END OF ty_s_file,

    ty_t_file TYPE STANDARD TABLE OF ty_s_file WITH EMPTY KEY.

  METHODS connect
    RAISING zcx_shk_ftp.

  METHODS disconnect.

  METHODS upload
    IMPORTING
      iv_remote_path TYPE clike
      iv_content     TYPE xstring
    RAISING
      zcx_shk_ftp.

  METHODS upload_text
    IMPORTING
      iv_remote_path TYPE clike
      iv_text        TYPE string
      iv_encoding    TYPE abap_encoding DEFAULT '4110'
    RAISING
      zcx_shk_ftp.

  METHODS download
    IMPORTING
      iv_remote_path    TYPE clike
    RETURNING
      VALUE(rv_content) TYPE xstring
    RAISING
      zcx_shk_ftp.

  METHODS list_directory
    IMPORTING
      iv_directory   TYPE clike DEFAULT '.'
    RETURNING
      VALUE(rt_files) TYPE ty_t_file
    RAISING
      zcx_shk_ftp.

  METHODS delete_file
    IMPORTING
      iv_remote_path TYPE clike
    RAISING
      zcx_shk_ftp.

  METHODS is_connected
    RETURNING VALUE(rv_connected) TYPE abap_bool.

ENDINTERFACE.
