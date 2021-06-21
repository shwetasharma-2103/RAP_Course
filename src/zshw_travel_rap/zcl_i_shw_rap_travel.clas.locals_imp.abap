CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O',
        accepted TYPE c LENGTH 1 VALUE 'A',
        canceled TYPE c LENGTH 1 VALUE 'X',
      END OF travel_status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS recalculateTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~recalculateTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS calculateTravelId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTravelId.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setInitialStatus.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS is_update_granted IMPORTING has_before_image      TYPE abap_bool
                                        overall_status        TYPE /dmo/overall_status
                              RETURNING VALUE(update_granted) TYPE abap_bool.


    METHODS is_delete_granted IMPORTING has_before_image      TYPE abap_bool
                                        overall_status        TYPE /dmo/overall_status
                              RETURNING VALUE(delete_granted) TYPE abap_bool.

    METHODS is_create_granted
      RETURNING VALUE(create_granted) TYPE abap_bool.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

*  Read all travel instances
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            FIELDS ( TravelStatus )
                WITH CORRESPONDING #( keys )
                RESULT DATA(Travels).


*    populate result table
* if status is already accepted then action accept travel is not applicable for an instance

    result = VALUE #( FOR travel IN travels
                       LET is_accepted = COND #( WHEN travel-TravelStatus = travel_status-accepted
                                                 THEN if_abap_behv=>fc-o-disabled
                                                 ELSE  if_abap_behv=>fc-o-enabled
                                               )
                           is_rejected = COND #( WHEN travel-TravelStatus = travel_status-canceled
                                                 THEN if_abap_behv=>fc-o-disabled
                                                 ELSE  if_abap_behv=>fc-o-enabled
                                               )
                       IN
                       (
                            %tky = travel-%tky
                            %action-acceptTravel = is_accepted
                            %action-rejectTravel = is_rejected
                       )
                      ).


  ENDMETHOD.

  METHOD acceptTravel.


*  Change status of all the keys
    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
           UPDATE
              FIELDS ( TravelStatus )
                WITH VALUE #( FOR key IN keys
                                ( %tky = key-%tky
                                  TravelStatus = travel_status-accepted
                                )
                             )
   FAILED failed
   REPORTED reported.

*       Fill the response table
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels
                       (  %tky = travel-%tky
                        %param = travel )
                     )   .

  ENDMETHOD.

  METHOD recalculateTotalPrice.

*  Table Type to store amt and curr code combination of all the bookings as each booking may have diff curr code
    TYPES: BEGIN OF ty_amt_per_curr_code,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amt_per_curr_code.

    DATA: amt_per_curr_code TYPE STANDARD TABLE OF ty_amt_per_curr_code.

* Read all Travel instances
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            FIELDS ( BookingFee CurrencyCode )
                WITH CORRESPONDING #( keys )
             RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

* Calculate total price for each travel instance
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

* Total price = booking fee + sum of flightprice of all the bookings
      amt_per_curr_code = VALUE #( ( amount = <travel>-BookingFee currency_code = <travel>-CurrencyCode ) ).

*            Read all associated bookings and calculate total price

      READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
          ENTITY Travel BY \_Booking
              FIELDS ( FlightPrice CurrencyCode )
                  WITH VALUE #( ( %tky = <travel>-%tky ) )
              RESULT DATA(Bookings).

      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amt_per_curr_code( amount = booking-FlightPrice
                                            currency_code = booking-CurrencyCode ) INTO amt_per_curr_code.
      ENDLOOP.


      CLEAR <travel>-TotalPrice.

      LOOP AT amt_per_curr_code INTO DATA(single_amt_per_curr_code).
        IF single_amt_per_curr_code-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amt_per_curr_code-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
                                  EXPORTING
                                      iv_amount = single_amt_per_curr_code-amount
                                      iv_currency_code_source = single_amt_per_curr_code-currency_code
                                      iv_currency_code_target = <travel>-CurrencyCode
                                      iv_exchange_rate_date = cl_abap_context_info=>get_system_date(  )
                                  IMPORTING
                                      ev_amount = DATA(total_booking_price_per_curr)
                                   ).
          <travel>-TotalPrice += total_booking_price_per_curr.

        ENDIF.
      ENDLOOP.
    ENDLOOP.

*       *       Write back the modified total price in buffer

    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            UPDATE FIELDS ( TotalPrice )
                WITH CORRESPONDING #( keys )
         REPORTED DATA(update_reported).


  ENDMETHOD.

  METHOD rejectTravel.

*  Reject travel for all the keys
    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            UPDATE
                FIELDS ( TravelStatus )
                    WITH VALUE #( FOR key IN keys
                                    (
                                        %tky = key-%tky
                                        TravelStatus = travel_status-canceled
                                     )
                                       )
  FAILED failed
        REPORTED reported.

*        Return travel instance for each key

    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(travels).


    result =  VALUE #( FOR travel IN travels
                       (
                           %tky = travel-%tky
                           %param = travel
                       )
                      )  .


  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            EXECUTE recalculateTotalPrice
                FROM CORRESPONDING #( keys )
            REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP reported ).




  ENDMETHOD.

  METHOD calculateTravelId.

*      Read travel instance

    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            FIELDS ( TravelId )
                WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    DELETE travels WHERE TravelId IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    SELECT SINGLE
           FROM zshw_rap_travel
               FIELDS MAX( travel_id ) AS TravelId
                   INTO @DATA(max_travel_id).

    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
       ENTITY travel
           UPDATE
               FROM VALUE #( FOR travel IN travels INDEX INTO i
                                ( %tky = travel-%tky
                                TravelId = max_travel_id + i
                                %control-TravelId = if_abap_behv=>mk-on
                           ) )
               REPORTED DATA(update_reported)
               .

    reported = CORRESPONDING #( DEEP update_reported ).


  ENDMETHOD.

  METHOD setInitialStatus.

*        Read travel instance data
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            FIELDS ( TravelStatus )
                WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

*          Delete entries where status is not initial

    DELETE travels WHERE TravelStatus IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

*      Modify the data

    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            UPDATE
               FIELDS ( TravelStatus )
                WITH VALUE #( FOR key IN keys (
                                %tky = key-%tky
                                TravelStatus = travel_status-open
                             ) )
               FAILED DATA(update_failed)
               REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported  ).

  ENDMETHOD.

  METHOD validateAgency.


* Read travel instances for the keys
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY travel
            FIELDS ( AgencyId )
                WITH CORRESPONDING #( keys )
                    RESULT DATA(travels).

* derive internal table with the agency ids, and perform a db select to validate the existance
    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

* optimize DB select: extract distinct non initial agency ids
    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.



      SELECT FROM /dmo/agency
      FIELDS agency_id
          FOR ALL ENTRIES IN @agencies
              WHERE agency_id = @agencies-agency_id
              INTO TABLE @DATA(agencies_db).



      LOOP AT travels INTO DATA(travel).
*                clear state messages that might exist
* Reported table has T100 messaged. Reported-Travel will have messages related travel entity
* new state_area. appending a new row with new state
        APPEND VALUE #(  %tky =  travel-%tky
                         %state_area = 'VALIDATE_AGENCY'
         )
       TO reported-travel.

        IF travel-AgencyId IS INITIAL OR NOT line_exists( agencies_db[ agency_id = travel-AgencyId ] ).

*      Append the current %tky to failed table. faield-travel contain failed keys of travel

          APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

*          append t100 message details to reported-travel
*           it has fields %tky(key), %state_area, %msg, and %element-field being validated
*           %msg pass the message exception class object. create using construtore passing the import parameters
*               like severity, textid (class name=>constant att name with the msg details (like msg class, msg no),
*                                       agencyId (this is the attribute value which will be passed to msgv1))


          APPEND VALUE #( %tky = travel-%tky
                          %state_area = 'VALIDATE_AGENCY'
                          %msg = NEW zcl_shw_rap_messages(
                                        severity = if_abap_behv_message=>severity-error
                                        textid = zcl_shw_rap_messages=>agency_unknown
                                        agencyId =  travel-AgencyId )
                          %element-agencyid = if_abap_behv=>mk-on
                          )
                   TO reported-travel.
        ENDIF.
      ENDLOOP.
    ENDIF.



  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Travel
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(travels).


    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE ADJACENT DUPLICATES FROM customers.

    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer
          FIELDS customer_id
              FOR ALL ENTRIES IN @customers
              WHERE customer_id = @customers-customer_id
              INTO TABLE @DATA(customers_db).

      LOOP AT travels INTO DATA(travel).

        APPEND VALUE #( %tky = travel-%tky
            %state_area = 'VALIDATE_CUSTOMER'
          )
    TO reported-travel.

        IF travel-CustomerId IS INITIAL OR NOT line_exists( customers_db[ customer_id = travel-CustomerId ] ).

          APPEND VALUE #( %tky = travel-%tky )
                      TO failed-travel.

          APPEND VALUE #( %tky = travel-%tky
                          %state_area = 'VALIDATE_CUSTOMER'
                          %msg = NEW zcl_shw_rap_messages(
                                      severity = if_abap_behv_message=>severity-error
                                      textid =  zcl_shw_rap_messages=>customer_unknown
                                      customerId = travel-CustomerId
                           )
                           %element-customerId = if_abap_behv=>mk-on
                         )
                   TO reported-travel.



        ENDIF.


      ENDLOOP.



    ENDIF.


  ENDMETHOD.

  METHOD validateDates.


*  Validate begin date not greater than end date
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY  Travel
        FIELDS ( TravelId  BeginDate EndDate )
        WITH CORRESPONDING #( keys )
    RESULT DATA(travels).


    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'VALIDATE_DATES'
                     )
         TO reported-travel.

      IF travel-BeginDate > travel-EndDate.

        APPEND VALUE #( %tky = travel-%tky )
                TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = NEW zcl_shw_rap_messages(
                                    severity = if_abap_behv_message=>severity-error
                                    textid = zcl_shw_rap_messages=>begin_date_after_end_date
                                    begindate = travel-BeginDate
                                    enddate = travel-EndDate
                                    travelid = travel-TravelId
                                 )
                         %element-begindate = if_abap_behv=>mk-on
                      )
         TO reported-travel.

      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date(  ).

        APPEND VALUE #( %tky = travel-%tky )
                TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = NEW zcl_shw_rap_messages(
                                    severity = if_abap_behv_message=>severity-error
                                    textid = zcl_shw_rap_messages=>begin_date_before_sys_date
                                    begindate = travel-BeginDate
                                 )
                         %element-begindate = if_abap_behv=>mk-on
                      )
         TO reported-travel.

      ENDIF.


    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA: has_before_image TYPE abap_bool,
          is_update_req    TYPE abap_bool,
          is_create_req    TYPE abap_bool,
          is_delete_req    TYPE abap_bool,
          update_granted   TYPE abap_bool,
          create_granted   TYPE abap_bool,
          delete_granted   TYPE abap_bool.

    DATA failed_travel LIKE LINE OF failed-travel.

*            Read existing travels
    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels)
    FAILED failed.

    CHECK Travels IS NOT INITIAL.

*            Here auth provided based on activity + Travel status
*            For travel status get the before image from DB
    SELECT FROM zshw_rap_travel
        FIELDS travel_uuid, overall_status
        FOR ALL ENTRIES IN @travels
        WHERE travel_uuid = @travels-TravelUuid
        ORDER BY PRIMARY KEY
        INTO TABLE @DATA(travel_before_image).
*Check if update is requested
    is_update_req = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on OR
                                 requested_authorizations-%action-acceptTravel = if_abap_behv=>mk-on OR
                                 requested_authorizations-%action-rejectTravel = if_abap_behv=>mk-on OR
                                 requested_authorizations-%assoc-_Booking = if_abap_behv=>mk-on or
                                 requested_authorizations-%action-Prepare = if_abap_behv=>mk-on or      "Drat related
                                 requested_authorizations-%action-Edit = if_abap_behv=>mk-on     "Draft Realated
                            THEN
                            abap_true
                            ELSE abap_false
                           ).
* Check if delete is requested
    is_delete_req = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                            THEN
                            abap_true
                            ELSE abap_false
                           ).

    LOOP AT travels INTO DATA(travel).
      update_granted = delete_granted = abap_false.

      READ TABLE travel_before_image INTO DATA(travel_before)
              WITH KEY travel_uuid = travel-TravelUuid BINARY SEARCH.
      has_before_image = COND #( WHEN sy-subrc = 0
                                 THEN abap_true
                                 ELSE abap_false
                                ).

      IF is_update_req = abap_true.
        update_granted = is_update_granted( has_before_image = has_before_image
                                            overall_status = travel-TravelStatus
                                          ).
        IF update_granted = abap_false.
          APPEND VALUE #( %tky = travel-%tky
                            %fail-cause = if_abap_behv=>cause-unauthorized
                         )
                          TO failed-travel.
          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW zcl_shw_rap_messages(
                                      severity = if_abap_behv_message=>severity-error
                                      textid  = zcl_shw_rap_messages=>unauthorized

                                   )
                         ) TO reported-travel.


        ENDIF.
      ENDIF.

      IF is_delete_req = abap_true.
        update_granted = is_delete_granted( has_before_image = has_before_image
                                            overall_status = travel-TravelStatus
                                          ).
        IF delete_granted = abap_false.
          APPEND VALUE #( %tky = travel-%tky
                            %fail-cause = if_abap_behv=>cause-unauthorized
                         )
                          TO failed-travel.
          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW zcl_shw_rap_messages(
                                      severity = if_abap_behv_message=>severity-error
                                      textid  = zcl_shw_rap_messages=>unauthorized

                                   )
                         ) TO reported-travel.


        ENDIF.
      ENDIF.

      append value #( %tky = travel-%tky
                      %update = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %action-acceptTravel = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %action-rejectTravel = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %assoc-_Booking = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %delete = cond #( when delete_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                     )
              to result.


    ENDLOOP.



  ENDMETHOD.

  METHOD is_create_granted.

    AUTHORITY-CHECK OBJECT 'ZAO_SH_TRS'
        ID  'ZA_SHW_TRS' FIELD travel_status
        ID 'ACTVT' FIELD '01'.

    create_granted = COND #( WHEN sy-subrc = 0
                             THEN abap_true
                             ELSE abap_false
                           ).

    create_granted = abap_true. "Simulation

  ENDMETHOD.

  METHOD is_delete_granted.

    IF has_before_image = abap_true.

      AUTHORITY-CHECK OBJECT 'ZAO_SH_TRS'
      ID  'ZA_SHW_TRS' FIELD travel_status
      ID 'ACTVT' FIELD '06'.

    ELSE.
      AUTHORITY-CHECK OBJECT 'ZAO_SH_TRS'
      ID  'ZA_SHW_TRS' DUMMY
      ID 'ACTVT' FIELD '06'.
    ENDIF.

    delete_granted = COND #( WHEN sy-subrc = 0
                               THEN abap_true
                               ELSE abap_false
                             ).


    delete_granted = abap_true. "Simulation

  ENDMETHOD.

  METHOD is_update_granted.


    IF has_before_image = abap_true.

      AUTHORITY-CHECK OBJECT 'ZAO_SH_TRS'
      ID  'ZA_SHW_TRS' FIELD travel_status
      ID 'ACTVT' FIELD '02'.

    ELSE.
      AUTHORITY-CHECK OBJECT 'ZAO_SH_TRS'
      ID  'ZA_SHW_TRS' DUMMY
      ID 'ACTVT' FIELD '02'.
    ENDIF.

    update_granted = COND #( WHEN sy-subrc = 0
                               THEN abap_true
                               ELSE abap_false
                             ).


    update_granted = abap_true. "Simulation

  ENDMETHOD.

ENDCLASS.
