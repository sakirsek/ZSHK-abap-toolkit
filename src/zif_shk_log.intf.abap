INTERFACE zif_shk_log PUBLIC.

  TYPES:
    ty_msg_type TYPE symsgty,

    BEGIN OF ty_s_msg,
      type    TYPE symsgty,
      id      TYPE symsgid,
      number  TYPE symsgno,
      message TYPE bapi_msg,
      v1      TYPE symsgv,
      v2      TYPE symsgv,
      v3      TYPE symsgv,
      v4      TYPE symsgv,
    END OF ty_s_msg,

    ty_t_msg TYPE STANDARD TABLE OF ty_s_msg WITH EMPTY KEY.

  METHODS add_free_text
    IMPORTING
      iv_text TYPE clike
      iv_type TYPE symsgty DEFAULT 'I'.

  METHODS add_bapiret2
    IMPORTING
      is_return TYPE bapiret2.

  METHODS add_bapiret2_table
    IMPORTING
      it_return TYPE bapiret2_t.

  METHODS add_sy_msg
    IMPORTING
      iv_type TYPE symsgty DEFAULT sy-msgty
      iv_id   TYPE symsgid DEFAULT sy-msgid
      iv_no   TYPE symsgno DEFAULT sy-msgno
      iv_v1   TYPE symsgv  DEFAULT sy-msgv1
      iv_v2   TYPE symsgv  DEFAULT sy-msgv2
      iv_v3   TYPE symsgv  DEFAULT sy-msgv3
      iv_v4   TYPE symsgv  DEFAULT sy-msgv4.

  METHODS add_exception
    IMPORTING
      io_exception TYPE REF TO cx_root
      iv_type      TYPE symsgty DEFAULT 'E'.

  METHODS save
    RETURNING VALUE(rv_log_handle) TYPE balloghndl
    RAISING   zcx_shk_log.

  METHODS get_messages
    RETURNING VALUE(rt_messages) TYPE ty_t_msg.

  METHODS has_errors
    RETURNING VALUE(rv_has_errors) TYPE abap_bool.

  METHODS get_count
    RETURNING VALUE(rv_count) TYPE i.

  METHODS clear.

ENDINTERFACE.
