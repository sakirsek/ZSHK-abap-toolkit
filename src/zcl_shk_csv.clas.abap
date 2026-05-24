CLASS zcl_shk_csv DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS table_to_csv
      IMPORTING
        it_table         TYPE ANY TABLE
        iv_separator     TYPE c DEFAULT ';'
        iv_with_header   TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_csv)    TYPE string.

    CLASS-METHODS csv_to_table
      IMPORTING
        iv_csv       TYPE string
        iv_separator TYPE c DEFAULT ';'
        iv_skip_header TYPE abap_bool DEFAULT abap_true
      CHANGING
        ct_table     TYPE STANDARD TABLE.

    CLASS-METHODS to_xstring
      IMPORTING
        iv_csv           TYPE string
        iv_encoding      TYPE abap_encoding DEFAULT '4110'
      RETURNING
        VALUE(rv_xstring) TYPE xstring.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shk_csv IMPLEMENTATION.
  METHOD table_to_csv.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    DATA lo_table TYPE REF TO cl_abap_tabledescr.
    lo_table ?= cl_abap_typedescr=>describe_by_data( it_table ).
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    lo_struct ?= lo_table->get_table_line_type( ).
    DATA(lt_components) = lo_struct->get_components( ).

    IF iv_with_header = abap_true.
      DATA lv_header TYPE string.
      LOOP AT lt_components INTO DATA(ls_comp_h).
        IF lv_header IS INITIAL.
          lv_header = ls_comp_h-name.
        ELSE.
          lv_header = lv_header && iv_separator && ls_comp_h-name.
        ENDIF.
      ENDLOOP.
      rv_csv = lv_header && cl_abap_char_utilities=>cr_lf.
    ENDIF.

    LOOP AT it_table ASSIGNING <ls_row>.
      DATA lv_line TYPE string.
      CLEAR lv_line.
      LOOP AT lt_components INTO DATA(ls_comp).
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row> TO <lv_field>.
        IF sy-subrc = 0.
          DATA lv_val TYPE string.
          lv_val = condense( CONV string( <lv_field> ) ).
          IF lv_line IS INITIAL.
            lv_line = lv_val.
          ELSE.
            lv_line = lv_line && iv_separator && lv_val.
          ENDIF.
        ENDIF.
      ENDLOOP.
      rv_csv = rv_csv && lv_line && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.
  ENDMETHOD.

  METHOD csv_to_table.
    DATA lt_lines TYPE string_table.
    FIELD-SYMBOLS <ls_row> TYPE any.
    FIELD-SYMBOLS <lv_field> TYPE any.

    SPLIT iv_csv AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_lines.
    IF lt_lines IS INITIAL.
      SPLIT iv_csv AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    ENDIF.

    DATA lv_start TYPE i VALUE 1.
    IF iv_skip_header = abap_true.
      lv_start = 2.
    ENDIF.

    DATA lo_table TYPE REF TO cl_abap_tabledescr.
    lo_table ?= cl_abap_typedescr=>describe_by_data( ct_table ).
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    lo_struct ?= lo_table->get_table_line_type( ).
    DATA(lt_components) = lo_struct->get_components( ).

    LOOP AT lt_lines INTO DATA(lv_line) FROM lv_start.
      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA lt_values TYPE string_table.
      SPLIT lv_line AT iv_separator INTO TABLE lt_values.

      APPEND INITIAL LINE TO ct_table ASSIGNING <ls_row>.
      DATA lv_idx TYPE i.
      LOOP AT lt_components INTO DATA(ls_comp).
        lv_idx = sy-tabix.
        DATA lv_cell TYPE string.
        READ TABLE lt_values INTO lv_cell INDEX lv_idx.
        IF sy-subrc = 0.
          ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row> TO <lv_field>.
          IF sy-subrc = 0.
            <lv_field> = condense( lv_cell ).
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_xstring.
    DATA lo_conv TYPE REF TO cl_abap_conv_out_ce.
    lo_conv = cl_abap_conv_out_ce=>create( encoding = iv_encoding ).
    lo_conv->convert( EXPORTING data = iv_csv IMPORTING buffer = rv_xstring ).
  ENDMETHOD.
ENDCLASS.
