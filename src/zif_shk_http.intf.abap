INTERFACE zif_shk_http PUBLIC.

  TYPES:
    BEGIN OF ty_s_name_value,
      name  TYPE string,
      value TYPE string,
    END OF ty_s_name_value,

    ty_t_name_value TYPE STANDARD TABLE OF ty_s_name_value WITH EMPTY KEY,

    BEGIN OF ty_s_response,
      status_code TYPE i,
      body        TYPE string,
      headers     TYPE ty_t_name_value,
    END OF ty_s_response.

  METHODS set_header
    IMPORTING
      iv_name  TYPE clike
      iv_value TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_http.

  METHODS set_timeout
    IMPORTING
      iv_timeout TYPE i DEFAULT 30
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_http.

  METHODS set_basic_auth
    IMPORTING
      iv_user     TYPE clike
      iv_password TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_http.

  METHODS get
    IMPORTING
      iv_path          TYPE clike DEFAULT ''
    RETURNING
      VALUE(rs_response) TYPE ty_s_response
    RAISING
      zcx_shk_http.

  METHODS post
    IMPORTING
      iv_path          TYPE clike DEFAULT ''
      iv_body          TYPE clike DEFAULT ''
    RETURNING
      VALUE(rs_response) TYPE ty_s_response
    RAISING
      zcx_shk_http.

  METHODS put
    IMPORTING
      iv_path          TYPE clike DEFAULT ''
      iv_body          TYPE clike DEFAULT ''
    RETURNING
      VALUE(rs_response) TYPE ty_s_response
    RAISING
      zcx_shk_http.

  METHODS patch
    IMPORTING
      iv_path          TYPE clike DEFAULT ''
      iv_body          TYPE clike DEFAULT ''
    RETURNING
      VALUE(rs_response) TYPE ty_s_response
    RAISING
      zcx_shk_http.

  METHODS delete
    IMPORTING
      iv_path          TYPE clike DEFAULT ''
    RETURNING
      VALUE(rs_response) TYPE ty_s_response
    RAISING
      zcx_shk_http.

  METHODS close.

ENDINTERFACE.
