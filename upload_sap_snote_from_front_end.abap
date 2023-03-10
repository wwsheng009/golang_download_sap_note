*&---------------------------------------------------------------------*
*& Report ZVI_UPLOAD_SNOTE_BATCH
*&---------------------------------------------------------------------*
*& upload sap snote file from front-end in batch mode
*& COPY from SCWN_NOTE_UPLOAD_INTERNAL
*&---------------------------------------------------------------------*
REPORT zvi_upload_note_batch.

CONSTANTS: true  TYPE char1 VALUE 'X',
           false TYPE char1 VALUE space.


DATA:
  lv_filetype    LIKE rlgrap-filetype,
  lv_file_filter TYPE string,
  lv_filename    TYPE string,
  lv_file        TYPE LINE OF filetable,
  lv_title       TYPE string,
  lv_file_table  TYPE filetable,
  lv_user_action TYPE i,
  lv_rc          TYPE i.

* dialog for file
CLASS cl_gui_frontend_services DEFINITION LOAD.
lv_file_filter = cl_gui_frontend_services=>filetype_all.
lv_title = TEXT-100.

CALL METHOD cl_gui_frontend_services=>file_open_dialog
  EXPORTING
    window_title     = lv_title
    default_filename = lv_filename
    file_filter      = lv_file_filter
    multiselection   = 'X'
  CHANGING
    file_table       = lv_file_table
    rc               = lv_rc
    user_action      = lv_user_action
  EXCEPTIONS
    OTHERS           = 1.

IF sy-subrc <> 0 OR lv_rc <= 0.
  EXIT.
ENDIF.

IF lv_user_action = cl_gui_frontend_services=>action_cancel.
  MESSAGE s020(scwn).
  EXIT.
ENDIF.


DATA: lv_total_table TYPE i.
lv_total_table = lines( lv_file_table ).

LOOP AT lv_file_table INTO lv_file.
  WRITE: / 'begin to upload:',lv_file-filename .

  PERFORM frm_display_indicator USING lv_total_table sy-tabix lv_file-filename.
  PERFORM upload_sap_snote USING lv_file.

  WRITE: / 'file uploaded:',lv_file-filename .
  WRITE: /.

ENDLOOP.


FORM upload_sap_snote USING lv_file   TYPE LINE OF filetable.



  FIELD-SYMBOLS: <ls_cwbnthead> TYPE cwbnthead.

  DATA: lv_cancel,

        lt_cont           LIKE cwbdata OCCURS 0,
        lt_cwbnthead      LIKE cwbnthead OCCURS 0,
        lt_cwbntstxt      LIKE cwbntstxt OCCURS 0,
        lt_cwbntdata      TYPE bcwbn_note_text OCCURS 0,
        lt_cwbntdata_html TYPE bcwbn_notehtml_text OCCURS 0,
        lt_cwbntvalid     LIKE cwbntvalid OCCURS 0,
        lt_cwbntci        LIKE cwbntci OCCURS 0,
        lt_cwbntfixed     LIKE cwbntfixed OCCURS 0,
        lt_cwbntgattr     LIKE cwbntgattr OCCURS 0,
        lt_cwbcihead      LIKE cwbcihead OCCURS 0,
        lt_cwbcidata      TYPE bcwbn_cinst_delta OCCURS 0,
        lt_cwbcivalid     LIKE cwbcivalid OCCURS 0,
        lt_cwbciinvld     LIKE cwbciinvld OCCURS 0,
        lt_cwbcifixed     LIKE cwbcifixed OCCURS 0,
        lt_cwbcidpndc     LIKE cwbcidpndc OCCURS 0,
        lt_cwbciobj       LIKE cwbciobj OCCURS 0,
        lt_cwbcmpnt       LIKE cwbcmpnt OCCURS 0,
        lt_cwbcmtext      LIKE cwbcmtext OCCURS 0,
        lt_cwbcmlast      LIKE cwbcmlast OCCURS 0,
        lt_cwbdehead      LIKE cwbdehead OCCURS 0,
        lt_cwbdeprdc      LIKE cwbdeprdc OCCURS 0,
        lt_cwbdetrack     LIKE cwbdetrack OCCURS 0,
        lt_cwbdeequiv     LIKE cwbdeequiv OCCURS 0,
        lt_cwbcidata_ref  TYPE cwb_deltas,


        ls_note           TYPE bcwbn_note,
        lt_notes          TYPE bcwbn_notes,
        ls_cwbnthead      LIKE cwbnthead.

  DATA: lv_data_bin        TYPE xstring,
        lv_code_delta_bin  TYPE xstring,
        lt_object_data_bin TYPE cwbci_t_objdelta,
        ls_numm_versno     TYPE cwbntkeyvs.
  DATA:
        lt_cwbcinstattr     TYPE cwbci_t_attr.

* upload file
*  READ TABLE lv_file_table INTO lv_file INDEX 1.
  lv_filename = lv_file-filename.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = lv_filename
    TABLES
      data_tab                = lt_cont
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'SCWN_NOTE_UNPACK'
    IMPORTING
      ev_data_bin           = lv_data_bin
      ev_code_delta_bin     = lv_code_delta_bin
      et_object_data_bin    = lt_object_data_bin
    TABLES
      tt_cont               = lt_cont
    EXCEPTIONS
      incompatible_versions = 1
      corrupt_data_file     = 2
      OTHERS                = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'SCWN_NOTE_UNPACK_XML'
    EXPORTING
      iv_data_bin           = lv_data_bin
      iv_code_delta_bin     = lv_code_delta_bin
      it_object_data_bin    = lt_object_data_bin
    IMPORTING
      et_cwbnthead          = lt_cwbnthead
      et_cwbntstxt          = lt_cwbntstxt
      et_cwbntdata          = lt_cwbntdata
      et_htmltext           = lt_cwbntdata_html
      et_cwbntvalid         = lt_cwbntvalid
      et_cwbntci            = lt_cwbntci
      et_cwbntfixed         = lt_cwbntfixed
      et_cwbntgattr         = lt_cwbntgattr
      et_cwbcihead          = lt_cwbcihead
      et_cwbcidata          = lt_cwbcidata
      et_cwbcidata_ref      = lt_cwbcidata_ref
      et_cwbcivalid         = lt_cwbcivalid
      et_cwbciinvld         = lt_cwbciinvld
      et_cwbcifixed         = lt_cwbcifixed
      et_cwbcidpndc         = lt_cwbcidpndc
      et_cwbciobj           = lt_cwbciobj
      et_cwbcmpnt           = lt_cwbcmpnt
      et_cwbcmtext          = lt_cwbcmtext
      et_cwbcmlast          = lt_cwbcmlast
      et_cwbdehead          = lt_cwbdehead
      et_cwbdeprdc          = lt_cwbdeprdc
      et_cwbdetrack         = lt_cwbdetrack
      et_cwbdeequiv         = lt_cwbdeequiv
      et_cwbcinstattr       = lt_cwbcinstattr
    EXCEPTIONS
      corrupt_data_file     = 1
      incompatible_versions = 2
      OTHERS                = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            RAISING corrupt_data_file.
  ENDIF.

* store note
  CALL FUNCTION 'SCWN_NOTE_STORE'
    EXPORTING
      it_cwbcmpnt       = lt_cwbcmpnt
      it_cwbdetrack     = lt_cwbdetrack
      it_cwbdehead      = lt_cwbdehead
      it_cwbdeequiv     = lt_cwbdeequiv
    TABLES
      tt_cwbnthead      = lt_cwbnthead
      tt_cwbntstxt      = lt_cwbntstxt
      tt_cwbntdata_html = lt_cwbntdata_html
      tt_cwbntdata      = lt_cwbntdata
      tt_cwbntvalid     = lt_cwbntvalid
      tt_cwbntci        = lt_cwbntci
      tt_cwbntfixed     = lt_cwbntfixed
      tt_cwbntgattr     = lt_cwbntgattr
      tt_cwbcihead      = lt_cwbcihead
      tt_cwbcidata      = lt_cwbcidata
      tt_cwbcidata_ref  = lt_cwbcidata_ref
      tt_cwbcivalid     = lt_cwbcivalid
      tt_cwbciinvld     = lt_cwbciinvld
      tt_cwbcifixed     = lt_cwbcifixed
      tt_cwbcidpndc     = lt_cwbcidpndc
      tt_cwbciobj       = lt_cwbciobj
      tt_cwbcinstattr   = lt_cwbcinstattr
    EXCEPTIONS
      failure           = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
*   store each stored note in download history
    LOOP AT lt_cwbnthead ASSIGNING <ls_cwbnthead>.
      ls_numm_versno-numm = <ls_cwbnthead>-numm.
      ls_numm_versno-versno = <ls_cwbnthead>-versno.
      CALL FUNCTION 'SCWN_NOTE_DOWNLOAD_HIST'
        EXPORTING
          is_note_version = ls_numm_versno
          iv_mode_write   = true
        EXCEPTIONS
          OTHERS          = 1.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDLOOP.
  ENDIF.

* data declaration done here to make implementation test green.
  DATA: lt_cwbcidpndc1    TYPE TABLE OF cwbcidpndc,
        ls_cwbcidpndc1    TYPE  cwbcidpndc,
        lt_cwbcidpndc_del TYPE TABLE OF cwbcidpndc,
        ls_cwbnthead1     TYPE cwbnthead.

*Deleting the dependency for the CI's which are deleted
  READ TABLE lt_cwbnthead  INTO ls_cwbnthead1 INDEX 1.
  SELECT * FROM cwbcidpndc INTO TABLE lt_cwbcidpndc1 WHERE ntnumm_d = ls_cwbnthead1-numm AND deptype = 'P'.
  IF sy-subrc = 0.
    LOOP AT lt_cwbcidpndc1 INTO ls_cwbcidpndc1.
* Check if the dependency exists with the existing CI's of the note
      READ TABLE lt_cwbntci WITH KEY cialeid = ls_cwbcidpndc1-cialeid_d TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND ls_cwbcidpndc1 TO lt_cwbcidpndc_del.
      ENDIF.
    ENDLOOP.
* Check if CI found which is deleted. Deleted from CWBCIDPNDC to avoid a repetetion of downloads.
    IF lt_cwbcidpndc_del IS NOT INITIAL.
**      delete only the latest version data.
**      All unwanted dependecies can be removed but deletion of latest deleted dependency done to maintain previous metadata.
      SORT lt_cwbcidpndc_del BY aleid versno DESCENDING.
      DELETE ADJACENT DUPLICATES FROM lt_cwbcidpndc_del COMPARING aleid.
*      delete lt_cwbcidpndc_del.
      DELETE cwbcidpndc FROM TABLE lt_cwbcidpndc_del.
      CLEAR lt_cwbcidpndc_del.
    ENDIF.
  ENDIF.

* update software component if necessary
  CALL FUNCTION 'SCWN_UPDATE_SOFTWARE_COMPONENT'
    TABLES
      tt_cwbcmpnt   = lt_cwbcmpnt
      tt_cwbcmtext  = lt_cwbcmtext
      tt_cwbcmlast  = lt_cwbcmlast
      tt_cwbdehead  = lt_cwbdehead
      tt_cwbdeprdc  = lt_cwbdeprdc
      tt_cwbdetrack = lt_cwbdetrack
      tt_cwbdeequiv = lt_cwbdeequiv
    EXCEPTIONS
      failure       = 1
      OTHERS        = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* classify notes
  LOOP AT lt_cwbnthead INTO ls_cwbnthead.
    ls_note-key-numm = ls_cwbnthead-numm.
    ls_note-key-versno = ls_cwbnthead-versno.
    APPEND ls_note TO lt_notes.
  ENDLOOP.

  CALL FUNCTION 'SCWB_NOTES_CLASSIFY'
    EXPORTING
      it_notes        = lt_notes
      iv_set_ntstatus = ' '.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  frm_display_indicator
*&---------------------------------------------------------------------*
FORM frm_display_indicator USING p_len p_processed p_text.

  DATA: l_process(16) TYPE p DECIMALS 4,   "这里的小数点可以自己设定
        l_text1(35)   VALUE '进度:',
        l_text2(16),             "把process放到text2中，process到100时，100.00,加上小数点，是6位,这里取最大值
        l_text3(1)    VALUE '%',
        l_text4(200)  TYPE c.

  DATA : l_text5(30) TYPE c,
         l_text6(30) TYPE c,
         l_text7(30) TYPE c.

  WRITE p_processed TO l_text5.
  WRITE p_len TO l_text6.

  CONDENSE l_text5.
  CONDENSE l_text6.
  CONCATENATE  l_text5 '/' l_text6 INTO l_text7.
  CONDENSE l_text7.

  l_process = p_processed * 100 / p_len.
  l_text2 = l_process.
  CONDENSE l_text2.

  DATA: str1 TYPE string.
  PERFORM show_progressbar USING l_process CHANGING str1.

  CONCATENATE l_text1 l_text2  l_text3  str1 l_text7 '当前表:' p_text INTO l_text4.
  CONDENSE l_text4.


  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = l_process
      text       = l_text4.

ENDFORM.                    "frm_display_indicator

*&---------------------------------------------------------------------*
*&      Form  show_progressbar
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PCT        text
*----------------------------------------------------------------------*
FORM show_progressbar USING upct TYPE p CHANGING txt TYPE string.

  DATA: fbar TYPE string,
        fmsg TYPE c LENGTH 70.

  CONSTANTS: percent1 TYPE c VALUE '▏',
             percent2 TYPE c VALUE '▎',
             percent3 TYPE c VALUE '▍',
             percent4 TYPE c VALUE '▌',
             percent5 TYPE c VALUE '▋',
             percent6 TYPE c VALUE '▊',
             percent7 TYPE c VALUE '▉',
             percent8 TYPE c VALUE '█'.

  DATA: totalb TYPE i .


  DATA: fmod   TYPE n,
        ftim   TYPE i,
        ffield TYPE c LENGTH 10,
        fidx   TYPE c LENGTH 3.

  FIELD-SYMBOLS: <fs> TYPE c.

  ftim = upct DIV 8.
  fmod = upct MOD 8.
  CLEAR: fbar.
  totalb = ( 100 DIV 8 ) - ftim .

  fbar = '['.
  DO ftim TIMES.
    CONCATENATE fbar percent8 INTO fbar.
  ENDDO.

  IF fmod NE 0.
    CONCATENATE 'percent' fmod INTO ffield.
    ASSIGN (ffield) TO <fs>.
    CONCATENATE fbar <fs> INTO fbar RESPECTING BLANKS.
  ENDIF.
  DO totalb TIMES.
    CONCATENATE fbar '--' INTO fbar.
  ENDDO.

  CONCATENATE fbar ']' INTO fbar.
  txt = fbar.
ENDFORM.                    "show_progressbar