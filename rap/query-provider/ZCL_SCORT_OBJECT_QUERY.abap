CLASS zcl_scort_object_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_query_params,
        devclass     TYPE devclass,
        object_type  TYPE trobjtype,
        author       TYPE uname,
        name_pattern TYPE string,
        detail_mode  TYPE abap_bool,
        detail_type  TYPE trobjtype,
        detail_name  TYPE sobj_name,
      END OF ty_query_params .

    METHODS parse_filter
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      RETURNING
        VALUE(rs_params) TYPE ty_query_params .

    METHODS parse_filter_from_sql
      IMPORTING
        iv_sql TYPE string
      CHANGING
        cs_params TYPE ty_query_params .

    METHODS apply_filter_values
      IMPORTING
        iv_fname    TYPE string
        iv_option   TYPE char2
        iv_low      TYPE string
      CHANGING
        cs_params   TYPE ty_query_params
        cv_type_eq  TYPE trobjtype
        cv_name_eq  TYPE sobj_name
        cv_type_set TYPE abap_bool
        cv_name_set TYPE abap_bool .

    METHODS normalize_params
      CHANGING
        cs_params TYPE ty_query_params .

    METHODS prepare_backend_pattern
      IMPORTING
        iv_pattern TYPE string
      RETURNING
        VALUE(rv_pattern) TYPE string .

    METHODS is_wildcard_value
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_wildcard) TYPE abap_bool .

    METHODS filter_raw_by_pattern
      IMPORTING
        iv_pattern TYPE string
      CHANGING
        ct_raw TYPE zscort_t_rfc_object .

    METHODS normalize_field_name
      IMPORTING
        iv_raw TYPE string
      RETURNING
        VALUE(rv_name) TYPE string .

    METHODS read_filter_ranges
      IMPORTING
        io_filter TYPE REF TO if_rap_query_filter
      CHANGING
        cs_params   TYPE ty_query_params
        cv_type_eq  TYPE trobjtype
        cv_name_eq  TYPE sobj_name
        cv_type_set TYPE abap_bool
        cv_name_set TYPE abap_bool .

    METHODS resolve_name_pattern
      IMPORTING
        io_filter TYPE REF TO if_rap_query_filter
      RETURNING
        VALUE(rv_pattern) TYPE string .

    METHODS fetch_list_objects
      IMPORTING
        io_repo   TYPE REF TO zcl_scort_repository
        is_params TYPE ty_query_params
      RETURNING
        VALUE(rt_raw) TYPE zscort_t_rfc_object .

ENDCLASS.


CLASS zcl_scort_object_query IMPLEMENTATION.

  METHOD normalize_field_name.

    DATA lv_work   TYPE string.
    DATA lv_suffix TYPE string.
    DATA lv_prefix TYPE string.

    lv_work = iv_raw.
    CHECK lv_work IS NOT INITIAL.

    SPLIT lv_work AT '.' INTO lv_prefix lv_suffix.
    IF lv_suffix IS NOT INITIAL.
      lv_work = lv_suffix.
    ENDIF.

    rv_name = lv_work.
    TRANSLATE rv_name TO UPPER CASE.
    CONDENSE rv_name NO-GAPS.

  ENDMETHOD.


  METHOD is_wildcard_value.

    DATA lv_val TYPE string.
    lv_val = iv_value.
    IF lv_val IS INITIAL.
      RETURN.
    ENDIF.
    IF find( val = lv_val sub = '*' ) >= 0
       OR find( val = lv_val sub = '%' ) >= 0.
      rv_wildcard = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD prepare_backend_pattern.

    rv_pattern = iv_pattern.
    CONDENSE rv_pattern NO-GAPS.
    IF rv_pattern IS INITIAL.
      RETURN.
    ENDIF.
    IF find( val = rv_pattern sub = '*' ) < 0
       AND find( val = rv_pattern sub = '%' ) < 0.
      rv_pattern = |{ rv_pattern }*|.
    ENDIF.

  ENDMETHOD.


  METHOD filter_raw_by_pattern.

    DATA:
      lv_cp   TYPE string,
      lt_keep TYPE zscort_t_rfc_object,
      ls_raw  TYPE zscort_s_rfc_object.

    CHECK iv_pattern IS NOT INITIAL.

    lv_cp = prepare_backend_pattern( iv_pattern ).

    LOOP AT ct_raw INTO ls_raw.
      IF ls_raw-obj_name CP lv_cp.
        APPEND ls_raw TO lt_keep.
      ENDIF.
    ENDLOOP.

    ct_raw = lt_keep.

  ENDMETHOD.


  METHOD normalize_params.

    REPLACE ALL OCCURRENCES OF `'` IN cs_params-devclass WITH ''.
    REPLACE ALL OCCURRENCES OF `'` IN cs_params-name_pattern WITH ''.
    REPLACE ALL OCCURRENCES OF `"` IN cs_params-devclass WITH ''.
    REPLACE ALL OCCURRENCES OF `"` IN cs_params-name_pattern WITH ''.
    REPLACE ALL OCCURRENCES OF `%` IN cs_params-name_pattern WITH `*`.
    CONDENSE cs_params-devclass NO-GAPS.
    CONDENSE cs_params-name_pattern NO-GAPS.

  ENDMETHOD.


  METHOD apply_filter_values.

    DATA lv_fname TYPE string.
    DATA lv_low   TYPE string.

    lv_fname = iv_fname.
    lv_low   = iv_low.

    IF lv_fname = 'DEVCLASS' OR lv_fname = 'PACKAGE'
       OR lv_fname CP '*DEVCLASS*' OR lv_fname CP '*PACKAGE*'.
      IF lv_low IS NOT INITIAL.
        cs_params-devclass = lv_low.
      ENDIF.

    ELSEIF lv_fname = 'OBJECTTYPE' OR lv_fname CP '*OBJECTTYPE*'.
      IF iv_option = 'EQ'.
        cv_type_eq = lv_low.
        cv_type_set = abap_true.
        cs_params-object_type = lv_low.
      ENDIF.

    ELSEIF lv_fname = 'AUTHOR' OR lv_fname CP '*AUTHOR*'.
      IF iv_option = 'EQ' AND lv_low IS NOT INITIAL.
        cs_params-author = lv_low.
      ENDIF.

    ELSEIF lv_fname = 'OBJECTNAME' OR lv_fname = 'OBJ_NAME'
       OR lv_fname CP '*OBJECTNAME*' OR lv_fname CP '*OBJ_NAME*'.
      IF lv_low IS NOT INITIAL.
        cs_params-name_pattern = lv_low.
        IF iv_option = 'EQ'
           AND is_wildcard_value( lv_low ) = abap_false.
          cv_name_eq = lv_low.
          cv_name_set = abap_true.
        ENDIF.
        IF iv_option = 'CP' OR iv_option = 'LK'.
          CLEAR: cv_name_eq, cv_name_set.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD parse_filter_from_sql.

    DATA lv_sql TYPE string.
    DATA lv_val TYPE string.

    lv_sql = iv_sql.
    TRANSLATE lv_sql TO UPPER CASE.
    REPLACE ALL OCCURRENCES OF `%2A` IN lv_sql WITH `*`.
    REPLACE ALL OCCURRENCES OF `%2a` IN lv_sql WITH `*`.

    FIND REGEX '''([^'']*\*[^'']*)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = lv_val.
    ENDIF.

    FIND REGEX 'OBJECTNAME\s+(?:EQ|=|LIKE|CP)\s+''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = lv_val.
    ENDIF.

    FIND REGEX 'OBJ_NAME\s+(?:EQ|=|LIKE|CP)\s+''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = lv_val.
    ENDIF.

    FIND REGEX 'MATCHESPATTERN\s*\(\s*OBJECTNAME\s*,\s*''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = lv_val.
    ENDIF.

    FIND REGEX 'STARTSWITH\s*\(\s*OBJECTNAME\s*,\s*''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = |{ lv_val }*|.
    ENDIF.

    FIND REGEX 'CONTAINS\s*\(\s*OBJECTNAME\s*,\s*''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-name_pattern = |*{ lv_val }*|.
    ENDIF.

    FIND REGEX 'DEVCLASS\s+(?:EQ|=|LIKE|CP)\s+''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-devclass = lv_val.
    ENDIF.

    FIND REGEX 'OBJECTTYPE\s+(?:EQ|=|LIKE|CP)\s+''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-object_type = lv_val.
    ENDIF.

    FIND REGEX 'AUTHOR\s+(?:EQ|=|LIKE|CP)\s+''([^'']+)''' IN lv_sql SUBMATCHES lv_val.
    IF sy-subrc = 0 AND lv_val IS NOT INITIAL.
      cs_params-author = lv_val.
    ENDIF.

  ENDMETHOD.


  METHOD resolve_name_pattern.

    DATA:
      lv_fname TYPE string,
      ls_tmp   TYPE ty_query_params.

    CHECK io_filter IS BOUND.

    TRY.
      DATA(lv_sql) = io_filter->get_as_sql_string( ).
      IF lv_sql IS NOT INITIAL.
        parse_filter_from_sql(
          EXPORTING iv_sql = lv_sql
          CHANGING  cs_params = ls_tmp ).
        IF ls_tmp-name_pattern IS NOT INITIAL.
          rv_pattern = ls_tmp-name_pattern.
          RETURN.
        ENDIF.
      ENDIF.
    CATCH cx_root.
    ENDTRY.

    TRY.
      DATA(lt_ranges) = io_filter->get_as_ranges( ).
      LOOP AT lt_ranges INTO DATA(ls_pair).
        lv_fname = normalize_field_name( ls_pair-name ).
        CHECK lv_fname CP '*OBJECTNAME*' OR lv_fname CP '*OBJ_NAME*'.
        LOOP AT ls_pair-range INTO DATA(ls_r).
          IF ls_r-sign <> 'E' AND ls_r-low IS NOT INITIAL.
            rv_pattern = ls_r-low.
            RETURN.
          ENDIF.
        ENDLOOP.
      ENDLOOP.

      LOOP AT lt_ranges INTO DATA(ls_any).
        LOOP AT ls_any-range INTO DATA(ls_rng).
          IF ls_rng-sign <> 'E'
             AND ls_rng-low IS NOT INITIAL
             AND find( val = ls_rng-low sub = '*' ) >= 0.
            rv_pattern = ls_rng-low.
            RETURN.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


  METHOD read_filter_ranges.

    DATA:
      lv_fname      TYPE string,
      lv_star_fname TYPE string.

    TRY.
      DATA(lt_ranges) = io_filter->get_as_ranges( ).
    CATCH cx_root.
      RETURN.
    ENDTRY.

    LOOP AT lt_ranges INTO DATA(ls_star).
      lv_star_fname = normalize_field_name( ls_star-name ).
      LOOP AT ls_star-range INTO DATA(ls_star_r).
        CHECK ls_star_r-sign <> 'E' AND ls_star_r-low IS NOT INITIAL.
        IF lv_star_fname CP '*OBJECTNAME*' OR lv_star_fname CP '*OBJ_NAME*'.
          cs_params-name_pattern = ls_star_r-low.
          EXIT.
        ENDIF.
        IF find( val = ls_star_r-low sub = '*' ) >= 0.
          cs_params-name_pattern = ls_star_r-low.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF cs_params-name_pattern IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_ranges INTO DATA(ls_pair).
      lv_fname = normalize_field_name( ls_pair-name ).
      CHECK lv_fname IS NOT INITIAL.

      LOOP AT ls_pair-range INTO DATA(ls_r).
        IF ls_r-sign = 'E'.
          CONTINUE.
        ENDIF.
        apply_filter_values(
          EXPORTING
            iv_fname  = lv_fname
            iv_option = ls_r-option
            iv_low    = ls_r-low
          CHANGING
            cs_params   = cs_params
            cv_type_eq  = cv_type_eq
            cv_name_eq  = cv_name_eq
            cv_type_set = cv_type_set
            cv_name_set = cv_name_set
        ).
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD parse_filter.

    DATA:
      lv_type_eq  TYPE trobjtype,
      lv_name_eq  TYPE sobj_name,
      lv_type_set TYPE abap_bool VALUE abap_false,
      lv_name_set TYPE abap_bool VALUE abap_false,
      lv_sql      TYPE string.

    DATA lo_filter TYPE REF TO if_rap_query_filter.

    CLEAR rs_params.

    lo_filter = io_request->get_filter( ).
    IF lo_filter IS NOT BOUND.
      RETURN.
    ENDIF.

    TRY.
      lv_sql = lo_filter->get_as_sql_string( ).
      IF lv_sql IS NOT INITIAL.
        parse_filter_from_sql(
          EXPORTING iv_sql = lv_sql
          CHANGING  cs_params = rs_params ).
      ENDIF.
    CATCH cx_root.
    ENDTRY.

    read_filter_ranges(
      EXPORTING io_filter = lo_filter
      CHANGING
        cs_params   = rs_params
        cv_type_eq  = lv_type_eq
        cv_name_eq  = lv_name_eq
        cv_type_set = lv_type_set
        cv_name_set = lv_name_set
    ).

    IF lv_type_set = abap_true
       AND lv_name_set = abap_true
       AND is_wildcard_value( CONV string( lv_name_eq ) ) = abap_false.
      rs_params-detail_mode = abap_true.
      rs_params-detail_type = lv_type_eq.
      rs_params-detail_name = lv_name_eq.
      CLEAR rs_params-name_pattern.
    ELSE.
      normalize_params( CHANGING cs_params = rs_params ).
      IF lv_name_set = abap_true AND rs_params-name_pattern IS INITIAL.
        rs_params-name_pattern = lv_name_eq.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD fetch_list_objects.

    DATA:
      lv_pat     TYPE string,
      lv_backend TYPE string.

    CHECK io_repo IS BOUND.

    lv_pat = is_params-name_pattern.
    CONDENSE lv_pat NO-GAPS.

    IF lv_pat IS NOT INITIAL.

      IF is_wildcard_value( lv_pat ) = abap_true.
        lv_backend = prepare_backend_pattern( lv_pat ).
      ELSE.
        lv_backend = lv_pat.
      ENDIF.

      io_repo->get_objects(
        EXPORTING
          iv_devclass     = is_params-devclass
          iv_object_type  = is_params-object_type
          iv_author       = is_params-author
          iv_name_pattern = lv_backend
        IMPORTING
          et_objects      = rt_raw ).

      IF rt_raw IS INITIAL.
    
        io_repo->get_objects(
          EXPORTING
            iv_devclass     = space
            iv_name_pattern = lv_backend
          IMPORTING
            et_objects      = rt_raw ).
      ENDIF.

      IF rt_raw IS INITIAL AND is_wildcard_value( lv_backend ) = abap_true.
        io_repo->get_objects(
          EXPORTING iv_devclass = space
          IMPORTING et_objects  = rt_raw ).
        filter_raw_by_pattern(
          EXPORTING iv_pattern = lv_backend
          CHANGING  ct_raw     = rt_raw ).
      ENDIF.

    ELSEIF is_params-devclass IS NOT INITIAL
        OR is_params-object_type IS NOT INITIAL
        OR is_params-author IS NOT INITIAL.

      io_repo->get_objects(
        EXPORTING
          iv_devclass     = is_params-devclass
          iv_object_type  = is_params-object_type
          iv_author       = is_params-author
        IMPORTING
          et_objects      = rt_raw ).

    ELSE.

     
      io_repo->get_objects(
        EXPORTING iv_devclass = space
        IMPORTING et_objects  = rt_raw ).

    ENDIF.

    
    DELETE rt_raw WHERE NOT ( devclass CP 'Y*' OR devclass CP 'Z*' ).

  ENDMETHOD.


  METHOD if_rap_query_provider~select.

    DATA:
      lt_all    TYPE STANDARD TABLE OF zi_scort_repository_object,
      lt_result TYPE STANDARD TABLE OF zi_scort_repository_object,
      lt_page   TYPE STANDARD TABLE OF zi_scort_repository_object,
      lt_keep   TYPE STANDARD TABLE OF zi_scort_repository_object,
      ls_params TYPE ty_query_params,
      ls_detail TYPE zscort_s_rfc_detail,
      ls_raw    TYPE zscort_s_rfc_object,
      ls_line   TYPE zi_scort_repository_object,
      lv_skip   TYPE i,
      lv_top    TYPE i,
      lv_pat    TYPE string,
      lv_cp     TYPE string.

    DATA:
      lo_repo   TYPE REF TO zcl_scort_repository,
      lo_paging TYPE REF TO if_rap_query_paging,
      lo_filter TYPE REF TO if_rap_query_filter.

    DATA lt_raw TYPE zscort_t_rfc_object.

    lo_repo = NEW zcl_scort_repository( ).
    ls_params = parse_filter( io_request ).

    lo_filter = io_request->get_filter( ).
    IF lo_filter IS BOUND AND ls_params-detail_mode = abap_false.
      lv_pat = resolve_name_pattern( lo_filter ).
      IF lv_pat IS NOT INITIAL.
        ls_params-name_pattern = lv_pat.
      ENDIF.
      normalize_params( CHANGING cs_params = ls_params ).
    ENDIF.

    IF ls_params-detail_mode = abap_true.

      TRY.
        lo_repo->get_object_detail(
          EXPORTING
            iv_pgmid         = 'R3TR'
            iv_object        = ls_params-detail_type
            iv_obj_name      = ls_params-detail_name
          IMPORTING
            es_object_detail = ls_detail ).
      CATCH cx_root.
        CLEAR ls_detail.
      ENDTRY.

      " ZSCORT_S_RFC_DETAIL khong co object/obj_name -> lay lai tu filter dau vao
      ls_line-ObjectType  = ls_params-detail_type.
      ls_line-ObjectName  = ls_params-detail_name.
      ls_line-DevClass    = ls_detail-devclass.
      ls_line-Author      = ls_detail-author.
      ls_line-CreatedBy   = ls_detail-created_by.
      ls_line-CreatedDate = ls_detail-created_date.
      ls_line-ChangedDate = ls_detail-changed_date.
      APPEND ls_line TO lt_all.

    ELSE.

      lt_raw = fetch_list_objects(
        io_repo   = lo_repo
        is_params = ls_params
      ).

      LOOP AT lt_raw INTO ls_raw.
        CLEAR ls_line.
        ls_line-ObjectType  = ls_raw-object.
        ls_line-ObjectName  = ls_raw-obj_name.
        ls_line-DevClass    = ls_raw-devclass.
        ls_line-Author      = ls_raw-author.
        ls_line-CreatedBy   = ''.
        ls_line-CreatedDate = '00000000'.
        ls_line-ChangedDate = '00000000'.
        APPEND ls_line TO lt_all.
      ENDLOOP.

      IF is_wildcard_value( ls_params-name_pattern ) = abap_true AND lt_all IS NOT INITIAL.
        lv_cp = prepare_backend_pattern( ls_params-name_pattern ).
        CLEAR lt_keep.
        LOOP AT lt_all INTO ls_line.
          IF ls_line-ObjectName CP lv_cp.
            APPEND ls_line TO lt_keep.
          ENDIF.
        ENDLOOP.
        lt_all = lt_keep.
      ENDIF.

    ENDIF.

    lo_paging = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      lv_skip = lo_paging->get_offset( ).
      lv_top  = lo_paging->get_page_size( ).
      IF lv_top < 0.
        CLEAR lv_top.
      ENDIF.
    ENDIF.

    IF lv_top > 0.
      LOOP AT lt_all INTO ls_line FROM lv_skip + 1 TO lv_skip + lv_top.
        APPEND ls_line TO lt_page.
      ENDLOOP.
      lt_result = lt_page.
    ELSE.
      lt_result = lt_all.
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( CONV int8( lines( lt_all ) ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
