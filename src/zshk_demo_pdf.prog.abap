*&---------------------------------------------------------------------*
*& ZSHK_DEMO_PDF — PDF module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_pdf.

PARAMETERS p_form TYPE tdsfname DEFAULT 'SF_EXAMPLE_01'.

START-OF-SELECTION.

  " from_smartform — get generated FM name
  TRY.
      DATA(lv_fmname) = zcl_shk_pdf=>from_smartform( iv_formname = p_form ).
      WRITE: / 'Smartform:', p_form.
      WRITE: / 'Generated FM:', lv_fmname.
      ULINE.

      " Call the smartform FM to get OTF
      DATA ls_output  TYPE ssfcrescl.
      DATA ls_control TYPE ssfctrlop.
      DATA ls_options TYPE ssfcompop.

      ls_control-no_dialog = abap_true.
      ls_control-getotf    = abap_true.

      CALL FUNCTION lv_fmname
        EXPORTING
          control_parameters = ls_control
          output_options     = ls_options
        IMPORTING
          job_output_info    = ls_output
        EXCEPTIONS
          OTHERS             = 1.

      IF sy-subrc <> 0.
        WRITE: / 'Smartform call failed. Try another form name.'.
        RETURN.
      ENDIF.

      DATA lv_otf_lines TYPE i.
      lv_otf_lines = lines( ls_output-otfdata ).
      WRITE: / 'OTF lines:', lv_otf_lines.

      " from_otf / otf_to_pdf — convert OTF to binary PDF
      DATA(lv_pdf) = zcl_shk_pdf=>from_otf( ls_output-otfdata ).

      DATA lv_size TYPE i.
      lv_size = xstrlen( lv_pdf ).
      WRITE: / 'PDF size:', lv_size, 'bytes'.
      WRITE: / 'PDF generated successfully.'.
      ULINE.

      " otf_to_pdf (alias test)
      DATA(lv_pdf2) = zcl_shk_pdf=>otf_to_pdf( ls_output-otfdata ).
      lv_size = xstrlen( lv_pdf2 ).
      WRITE: / 'otf_to_pdf alias:', lv_size, 'bytes'.

    CATCH zcx_shk_mail INTO DATA(lo_err).
      WRITE: / 'Error:', lo_err->get_text( ).
  ENDTRY.
