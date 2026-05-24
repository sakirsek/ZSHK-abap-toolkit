CLASS zcl_shk_return DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS success
      IMPORTING
        iv_message       TYPE clike
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS error
      IMPORTING
        iv_message       TYPE clike
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS warning
      IMPORTING
        iv_message       TYPE clike
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS info
      IMPORTING
        iv_message       TYPE clike
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS from_sy_msg
      IMPORTING
        iv_type          TYPE symsgty DEFAULT sy-msgty
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS from_exception
      IMPORTING
        io_exception     TYPE REF TO cx_root
        iv_type          TYPE symsgty DEFAULT 'E'
      RETURNING
        VALUE(rs_return) TYPE bapiret2.

    CLASS-METHODS has_errors
      IMPORTING
        it_return        TYPE bapiret2_t
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    CLASS-METHODS collect_errors
      IMPORTING
        it_return          TYPE bapiret2_t
      RETURNING
        VALUE(rt_errors)   TYPE bapiret2_t.

    CLASS-METHODS to_string
      IMPORTING
        is_return        TYPE bapiret2
      RETURNING
        VALUE(rv_text)   TYPE string.

    CLASS-METHODS table_to_string
      IMPORTING
        it_return        TYPE bapiret2_t
        iv_separator     TYPE clike DEFAULT cl_abap_char_utilities=>newline
      RETURNING
        VALUE(rv_text)   TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS build
      IMPORTING
        iv_type          TYPE symsgty
        iv_message       TYPE clike
      RETURNING
        VALUE(rs_return) TYPE bapiret2.
ENDCLASS.

CLASS zcl_shk_return IMPLEMENTATION.
  METHOD success.
    rs_return = build( iv_type = 'S' iv_message = iv_message ).
  ENDMETHOD.

  METHOD error.
    rs_return = build( iv_type = 'E' iv_message = iv_message ).
  ENDMETHOD.

  METHOD warning.
    rs_return = build( iv_type = 'W' iv_message = iv_message ).
  ENDMETHOD.

  METHOD info.
    rs_return = build( iv_type = 'I' iv_message = iv_message ).
  ENDMETHOD.

  METHOD build.
    rs_return-type       = iv_type.
    rs_return-id         = 'ZSHK_MSG'.
    rs_return-number     = '001'.
    rs_return-message    = iv_message.
    rs_return-message_v1 = iv_message.
  ENDMETHOD.

  METHOD from_sy_msg.
    rs_return-type       = iv_type.
    rs_return-id         = sy-msgid.
    rs_return-number     = sy-msgno.
    rs_return-message_v1 = sy-msgv1.
    rs_return-message_v2 = sy-msgv2.
    rs_return-message_v3 = sy-msgv3.
    rs_return-message_v4 = sy-msgv4.

    MESSAGE ID sy-msgid TYPE iv_type NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
      INTO rs_return-message.
  ENDMETHOD.

  METHOD from_exception.
    rs_return-type    = iv_type.
    rs_return-id      = 'ZSHK_MSG'.
    rs_return-number  = '001'.
    rs_return-message = io_exception->get_text( ).
    rs_return-message_v1 = rs_return-message.
  ENDMETHOD.

  METHOD has_errors.
    rv_result = xsdbool( line_exists( it_return[ type = 'E' ] )
                      OR line_exists( it_return[ type = 'A' ] ) ).
  ENDMETHOD.

  METHOD collect_errors.
    LOOP AT it_return INTO DATA(ls_return)
      WHERE type = 'E' OR type = 'A'.
      APPEND ls_return TO rt_errors.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_string.
    IF is_return-message IS NOT INITIAL.
      rv_text = is_return-message.
    ELSE.
      rv_text = |{ is_return-type }: { is_return-id }-{ is_return-number }|.
    ENDIF.
  ENDMETHOD.

  METHOD table_to_string.
    LOOP AT it_return INTO DATA(ls_return).
      IF rv_text IS INITIAL.
        rv_text = to_string( ls_return ).
      ELSE.
        rv_text = rv_text && iv_separator && to_string( ls_return ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
