REPORT zsas_rapor_alv.

DATA: gv_ebeln TYPE ekko-ebeln,
      gv_aedat TYPE ekko-aedat,
      gv_werks TYPE ekpo-werks.

SELECT-OPTIONS: so_ebeln FOR gv_ebeln,
                so_aedat FOR gv_aedat,
                so_werks FOR gv_werks.

START-OF-SELECTION.
  SELECT * FROM zc_sas_rapor
    WHERE sasno IN @so_ebeln
      AND sasyaratmatarihi IN @so_aedat
      AND uretimyeri IN @so_werks
    ORDER BY sasno, saskalem
    INTO TABLE @DATA(gt_rapor).

  IF gt_rapor IS INITIAL.
    MESSAGE 'Kayıt bulunamadı' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = DATA(go_alv)
        CHANGING  t_table      = gt_rapor ).
      go_alv->get_functions( )->set_all( abap_true ).
      go_alv->get_columns( )->set_optimize( abap_true ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(gx).
      MESSAGE gx TYPE 'E'.
  ENDTRY.
