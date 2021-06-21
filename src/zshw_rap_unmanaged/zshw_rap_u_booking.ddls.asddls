@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'SHW RAP UNM Booking'
define view entity ZSHW_RAP_U_BOOKING as select from /dmo/booking
association to parent ZSHW_RAP_U_TRAVEL as _Travel on $projection.TravelId = _Travel.TravelId
  association [1..1] to /DMO/I_Customer   as _Customer   on  $projection.CustomerId = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier    as _Carrier    on  $projection.CarrierId = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection as _Connection on  $projection.CarrierId    = _Connection.AirlineID
                                                         and $projection.ConnectionId = _Connection.ConnectionID
  association [1..1] to /DMO/I_Flight     as _Flight     on  $projection.CarrierId    = _Flight.AirlineID
                                                         and $projection.ConnectionId = _Flight.ConnectionID
                                                         and $projection.FlightDate   = _Flight.FlightDate
  association [1..1] to I_Currency as _Currency  on $projection.CurrencyCode = _Currency.Currency
{
      key travel_id         as TravelId,
      key booking_id        as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      carrier_id            as CarrierId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
//      Associations
      _Travel,
      _Customer,
      _Carrier,
      _Connection,
      _Flight,
      _Currency
}
