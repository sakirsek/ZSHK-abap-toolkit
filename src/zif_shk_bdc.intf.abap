INTERFACE zif_shk_bdc PUBLIC.

  METHODS add_screen
    IMPORTING
      iv_program TYPE bdc_prog
      iv_dynpro  TYPE bdc_dynr.

  METHODS add_field
    IMPORTING
      iv_name  TYPE fnam_____4
      iv_value TYPE clike.

  METHODS add_okcode
    IMPORTING
      iv_okcode TYPE clike.

  METHODS execute
    IMPORTING
      iv_tcode   TYPE sytcode
      iv_dismode TYPE ctu_params-dismode DEFAULT 'N'
      iv_updmode TYPE ctu_params-updmode DEFAULT 'S'
    RETURNING
      VALUE(rt_messages) TYPE bapiret2_t
    RAISING
      zcx_shk_bdc.

  METHODS get_bdcdata
    RETURNING VALUE(rt_bdcdata) TYPE tab_bdcdata.

  METHODS clear.

ENDINTERFACE.
