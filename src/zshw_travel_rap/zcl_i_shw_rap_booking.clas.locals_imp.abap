CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateBookingId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateBookingId.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateBookingId.

    DATA max_booking_id TYPE /dmo/booking_id.
    DATA update TYPE TABLE FOR UPDATE zi_shw_rap_travel\\Booking.

* Read all travels of the reported bookings
* if multiple bookings for a travel the travel is read only once

    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Booking BY \_Travel
            FIELDS ( TravelId )
               WITH CORRESPONDING #( keys )
       RESULT DATA(Travels).


* Process all the affected travels
    LOOP AT travels INTO DATA(travel).

*            read bookings of each affected travel

      READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
          ENTITY Travel BY \_Booking
              FIELDS ( BookingId )
                  WITH CORRESPONDING #( keys )
          RESULT DATA(Bookings).

*             Find the max used booking id in all the booking ids of this travel
      max_booking_id = '0000'.
      LOOP AT Bookings INTO DATA(booking).
        IF booking-BookingId > max_booking_id.
          max_booking_id = booking-BookingId.
        ENDIF.
      ENDLOOP.
* Provide booking id for all the bookings for which none booking id yet
* populate the %tky and booking id combination in update table which will be used to update the Bookings

      LOOP AT bookings INTO booking WHERE BookingId IS INITIAL.
        max_booking_id += 10.
        APPEND VALUE #( %tky = booking-%tky
                          bookingId  = max_booking_id
                      ) TO update.
      ENDLOOP.


    ENDLOOP.


    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
     ENTITY Booking
         UPDATE FIELDS ( BookingId ) WITH update
         REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    READ ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
        ENTITY Booking BY \_Travel
        FIELDS ( TravelUuid )
            WITH CORRESPONDING #( keys )
        RESULT DATA(Travels)
        FAILED DATA(failed_read).

    MODIFY ENTITIES OF zi_shw_rap_travel IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalculateTotalPrice
      FROM CORRESPONDING #( travels )
  REPORTED DATA(execute_reported).

    reported = CORRESPONDING #( DEEP execute_reported ) .


  ENDMETHOD.

ENDCLASS.
