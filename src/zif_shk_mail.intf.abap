INTERFACE zif_shk_mail PUBLIC.

  TYPES:
    BEGIN OF ty_s_attachment,
      filename TYPE string,
      content  TYPE xstring,
      mimetype TYPE string,
    END OF ty_s_attachment,

    ty_t_attachment TYPE STANDARD TABLE OF ty_s_attachment WITH EMPTY KEY.

  METHODS set_subject
    IMPORTING
      iv_subject TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS set_body_text
    IMPORTING
      iv_body TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS set_body_html
    IMPORTING
      iv_html TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS add_recipient
    IMPORTING
      iv_address TYPE clike
      iv_copy    TYPE char1 DEFAULT space
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS add_attachment
    IMPORTING
      iv_filename TYPE clike
      iv_content  TYPE xstring
      iv_mimetype TYPE clike DEFAULT 'application/octet-stream'
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS add_attachment_csv
    IMPORTING
      iv_filename TYPE clike
      iv_csv      TYPE string
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS set_sender
    IMPORTING
      iv_address TYPE clike
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS set_importance
    IMPORTING
      iv_importance TYPE bcs_docimp DEFAULT '5'
    RETURNING
      VALUE(ro_self) TYPE REF TO zif_shk_mail.

  METHODS send
    IMPORTING
      iv_commit TYPE abap_bool DEFAULT abap_true
    RAISING
      zcx_shk_mail.

ENDINTERFACE.
