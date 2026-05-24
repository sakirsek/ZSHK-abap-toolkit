CLASS zcl_shk_pdf DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS from_otf
      IMPORTING
        it_otf          TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_pdf)   TYPE xstring
      RAISING
        zcx_shk_mail.

    CLASS-METHODS from_smartform
      IMPORTING
        iv_formname       TYPE tdsfname
        iv_language       TYPE sy-langu DEFAULT sy-langu
      RETURNING
        VALUE(rv_fmname)  TYPE rs38l_fnam
      RAISING
        zcx_shk_mail.

    CLASS-METHODS otf_to_pdf
      IMPORTING
        it_otf          TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_pdf)   TYPE xstring
      RAISING
        zcx_shk_mail.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shk_pdf IMPLEMENTATION.
  METHOD from_otf.
    DATA lt_lines TYPE STANDARD TABLE OF tline.
    DATA lv_size  TYPE i.

    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = 'PDF'
      IMPORTING
        bin_filesize          = lv_size
      TABLES
        otf                   = it_otf
        lines                 = lt_lines
      EXCEPTIONS
        err_max_linewidth     = 1
        err_format            = 2
        err_conv_not_possible = 3
        err_bad_otf           = 4
        OTHERS                = 5.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_mail
        EXPORTING iv_text = |CONVERT_OTF failed: { sy-msgv1 }|.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_size
      IMPORTING
        buffer       = rv_pdf
      TABLES
        binary_tab   = lt_lines
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
  ENDMETHOD.

  METHOD from_smartform.
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = iv_formname
      IMPORTING
        fm_name            = rv_fmname
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_mail
        EXPORTING iv_text = |Smartform { iv_formname } not found|.
    ENDIF.
  ENDMETHOD.

  METHOD otf_to_pdf.
    rv_pdf = from_otf( it_otf ).
  ENDMETHOD.
ENDCLASS.
