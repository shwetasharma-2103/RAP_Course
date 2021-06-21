CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS rba_Booking FOR READ
      IMPORTING keys_rba FOR READ Travel\_Booking FULL result_requested RESULT result LINK association_links.

    METHODS cba_Booking FOR MODIFY
      IMPORTING entities_cba FOR CREATE Travel\_Booking.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD create.

*        Input is entities

    DATA legacy_entity_in TYPE /dmo/travel.
    DATA legacy_entity_out TYPE /dmo/travel.
    DATA messages TYPE /dmo/t_message.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

* using mapping to control structure move each i/p entity to bus logic entity

      legacy_entity_in = CORRESPONDING #( <entity> MAPPING FROM ENTITY USING CONTROL ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_CREATE'
        EXPORTING
*move corresponding from legacy_entity_in into structure type /dmo/s_travel_in
          is_travel   = CORRESPONDING /dmo/s_travel_in( legacy_entity_in )
        IMPORTING
          es_travel   = legacy_entity_out
          et_messages = messages.

      IF messages IS INITIAL.
*              fill mapping in mapped table mapping of %cid( i/p control id) and travelId returned by the bapi
        APPEND VALUE #( %cid = <entity>-%cid
                        travelid = legacy_entity_out-travel_id
                       ) TO mapped-travel.
      ELSE.

*                 Fill failed
        APPEND VALUE #(
                        travelid = legacy_entity_out-travel_id
                      ) TO failed-travel.
*                  Fill Reported

        APPEND VALUE #( travelid = legacy_entity_out-travel_id
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = CONV #( messages[ 1 ]-msgty )
                                           )
                      ) TO reported-travel.


      ENDIF.




    ENDLOOP.


  ENDMETHOD.

  METHOD update.

*        *        Input is entities

    DATA legacy_entity_in TYPE /dmo/travel.
    DATA legacy_entity_x TYPE /dmo/s_travel_inx.
    DATA messages TYPE /dmo/t_message.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

* using mapping to control structure move each i/p entity to bus logic entity

      legacy_entity_in = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).
      legacy_entity_x-travel_id = <entity>-TravelId.
      legacy_entity_x-_intx = CORRESPONDING zshw_rap_x_travel( <entity> MAPPING FROM ENTITY ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
*move corresponding from legacy_entity_in into structure type /dmo/s_travel_in. Pass is_travel and is_travelx as well.
*is_travelx is th control structure which has boolean X for the fields to be updated.
          is_travel   = CORRESPONDING /dmo/s_travel_in( legacy_entity_in )
          is_travelx  = legacy_entity_x
        IMPORTING
          et_messages = messages.

      IF messages IS INITIAL.
*              fill mapping in mapped table mapping of %cid( i/p control id) and travelId returned by the bapi
        APPEND VALUE #( travelid = <entity>-TravelId ) TO mapped-travel.
      ELSE.

*                 Fill failed
        APPEND VALUE #(
                        travelid = <entity>-TravelId
                      ) TO failed-travel.
*                  Fill Reported

        APPEND VALUE #( travelid = <entity>-TravelId
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = CONV #( messages[ 1 ]-msgty )
                                           )
                      ) TO reported-travel.


      ENDIF.




    ENDLOOP.

  ENDMETHOD.

  METHOD delete.

*    *        Input is keys
    DATA messages TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_DELETE'
        EXPORTING
*move corresponding from legacy_entity_in into structure type /dmo/s_travel_in
          iv_travel_id = <key>-TravelId
        IMPORTING
          et_messages  = messages.

      IF messages IS INITIAL.
*              append travelId to mapped
        APPEND VALUE #(
                        travelid = <key>-TravelId
                       ) TO mapped-travel.
      ELSE.

*                 Fill failed
        APPEND VALUE #(
                        travelid = <key>-TravelId
                      ) TO failed-travel.
*                  Fill Reported

        APPEND VALUE #( travelid = <key>-TravelId
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = CONV #( messages[ 1 ]-msgty )
                                           )
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD read.

    DATA legacy_data_out TYPE /dmo/travel.
    DATA messages TYPE /dmo/t_message.

*    input keys
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <key>-TravelId
        IMPORTING
          es_travel    = legacy_data_out
          et_messages  = messages.

      IF messages IS INITIAL.
* append travelId to mapped
        INSERT CORRESPONDING #( legacy_data_out MAPPING TO ENTITY ) INTO TABLE result.

      ELSE.

        LOOP AT messages ASSIGNING FIELD-SYMBOL(<message>).
          APPEND VALUE #( travelid = <key>-TravelId
                          %fail-cause = COND #(
                                          WHEN <message>-msgty = 'E' AND
                                          ( <message>-msgno = '016' OR <message>-msgno = '009' )
                                          THEN if_abap_behv=>cause-not_found
                                          ELSE  if_abap_behv=>cause-unspecific
                                          )
                        ) TO failed-travel.
        ENDLOOP.
      ENDIF.



    ENDLOOP.

  ENDMETHOD.

  METHOD lock.

*  Instantiate lock
    DATA(lock) = cl_abap_lock_object_factory=>get_instance( iv_name = '/DMO/ETravel').

*    Input keys

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      TRY.
          lock->enqueue(
                          it_parameter = VALUE #( ( name = 'TRAVEL_ID' value = REF #( <key>-TravelId ) ) )

                       ).
        CATCH cx_abap_foreign_lock INTO DATA(lx_foreign_lock).

*                Fill failed
          APPEND VALUE #(
                          travelid = <key>-TravelId
                        ) TO failed-travel.
*                  Fill Reported

          APPEND VALUE #( travelid = <key>-TravelId
                          %msg = new_message( id = 'DMO/CH_FLIGHT_LEGAC'
                                              number = '032'
                                              v1 = <key>-TravelId
                                              v2 = lx_foreign_lock->user_name
                                              severity = CONV #('E')
                                             )
                        ) TO reported-travel.
      ENDTRY.

    ENDLOOP.


  ENDMETHOD.

  METHOD rba_Booking.

    DATA: legacy_parent_entity_out TYPE /dmo/travel,
          legacy_entities_out      TYPE /dmo/t_booking,
          entity                   LIKE LINE OF result,
          message                  TYPE /dmo/t_message.


    LOOP AT keys_rba  ASSIGNING FIELD-SYMBOL(<key_rba>) GROUP  BY <key_rba>-TravelId.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <key_rba>-travelid
        IMPORTING
          es_travel    = legacy_parent_entity_out
          et_booking   = legacy_entities_out
          et_messages  = message.

      IF message IS INITIAL.

        LOOP AT legacy_entities_out ASSIGNING FIELD-SYMBOL(<fs_booking>).
          "fill link table with key fields

          INSERT
            VALUE #(
                source-%key = <key_rba>-%key
                target-%key = VALUE #(
                  TravelID  = <fs_booking>-travel_id
                  BookingID = <fs_booking>-booking_id
              )
            )
            INTO TABLE  association_links .

          "fill result parameter with flagged fields
          IF result_requested = abap_true.

            entity = CORRESPONDING #( <fs_booking> MAPPING TO ENTITY ).
            INSERT entity INTO TABLE result.

          ENDIF.

        ENDLOOP.

      ELSE.
        "fill failed table in case of error

        failed-travel = VALUE #(
          BASE failed-travel
          FOR msg IN message (
            %key = <key_rba>-TravelID
            %fail-cause = COND #(
              WHEN msg-msgty = 'E' AND  ( msg-msgno = '016' OR msg-msgno = '009' )
              THEN if_abap_behv=>cause-not_found
              ELSE if_abap_behv=>cause-unspecific
            )
          )
        ).

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD cba_Booking.

*  Executed when Booking is created via Travel parent entity
    DATA messages TYPE /dmo/t_message.
    DATA lt_booking_old TYPE /dmo/t_booking.
    DATA entity TYPE /dmo/booking.
    DATA last_booking_id TYPE /dmo/booking_id VALUE '0'.

    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<entity_cba>).

      DATA(travelid) = <entity_cba>-TravelId.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id   = <entity_cba>-TravelId
        IMPORTING
          et_booking_old = lt_booking_old
          et_messages    = messages.


      IF messages IS INITIAL.
        IF lt_booking_old IS NOT INITIAL.
          last_booking_id = lt_booking_old[ lines( lt_booking_old ) ]-booking_id.
        ENDIF.

        LOOP AT <entity_cba>-%target ASSIGNING FIELD-SYMBOL(<entity>).

          entity = CORRESPONDING #( <entity> MAPPING FROM ENTITY USING CONTROL ).

          last_booking_id += 1.
          entity-booking_id = last_booking_id.

          CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
            EXPORTING
              is_travel   = VALUE /dmo/s_travel_in( travel_id = travelid )
              is_travelx  = VALUE /dmo/s_travel_inx( travel_id = travelid )
              it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( entity ) ) )
              it_bookingx = VALUE /dmo/t_booking_inx(
                                  (
                                  booking_id = entity-booking_id
                                  action_code = /dmo/if_flight_legacy=>action_code-create
                                   ) )
            IMPORTING
              et_messages = messages.

          IF messages IS INITIAL.
            INSERT VALUE #(
                            %cid = <entity>-%cid
                            travelid = travelid
                            bookingid = entity-booking_id
                         ) INTO TABLE mapped-booking.
          ELSE.

*Fill failed
            APPEND VALUE #(
                            bookingid = entity-booking_id
                          ) TO failed-booking.

            LOOP AT messages ASSIGNING FIELD-SYMBOL(<message>).
              APPEND VALUE #( %cid = <entity>-%cid
                              travelid = travelid
                             %msg = new_message( id = <message>-msgid
                                            number = <message>-msgno
                                            v1 = <message>-msgv1
                                            v2 = <message>-msgv2
                                            v3 = <message>-msgv3
                                            v4 = <message>-msgv4
                                            severity = CONV #( <message>-msgty )
                                           )
                            ) TO reported-booking.
            ENDLOOP.

          ENDIF.


        ENDLOOP.

      ELSE.
        APPEND VALUE #(
                            bookingid = entity-booking_id
                          ) TO failed-booking.

        LOOP AT messages ASSIGNING <message>.
          APPEND VALUE #( %cid = <entity>-%cid
                          travelid = travelid
                         %msg = new_message( id = <message>-msgid
                                        number = <message>-msgno
                                        v1 = <message>-msgv1
                                        v2 = <message>-msgv2
                                        v3 = <message>-msgv3
                                        v4 = <message>-msgv4
                                        severity = CONV #( <message>-msgty )
                                       )
                        ) TO reported-booking.
        ENDLOOP.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

ENDCLASS.

CLASS lsc_zshw_rap_u_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS check_before_save REDEFINITION.
    METHODS finalize REDEFINITION.
    METHODS save REDEFINITION.

ENDCLASS.

CLASS lsc_zshw_rap_u_travel  IMPLEMENTATION.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD finalize.
  ENDMETHOD.

  METHOD save.
*legacy function which reads data from buffer held by FMs down to the database
    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_SAVE'.
  ENDMETHOD.


ENDCLASS.
