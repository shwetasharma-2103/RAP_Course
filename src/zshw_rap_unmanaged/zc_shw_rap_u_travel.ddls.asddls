@EndUserText.label: 'Projection ZSHW_RAP_U_TRAVEL'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TravelID']
define root view entity ZC_SHW_RAP_U_TRAVEL as projection on ZSHW_RAP_U_TRAVEL {
  
  @Search.defaultSearchElement: true
  key TravelId,
  
  @Search.defaultSearchElement: true
  @ObjectModel.text.element: ['AgencyName']
  @Consumption.valueHelpDefinition: [{ 
                      entity: { name: '/DMO/I_AGENCY',
                                element: 'AgencyID' } }]
  AgencyId,
  
  _Agency.name as AgencyName,
  
  @Search.defaultSearchElement: true
  @ObjectModel.text.element: ['CustomerName']
  @Consumption.valueHelpDefinition: [{ 
                      entity: { name: '/DMO/I_CUSTOMER',
                                element: 'CustomerID' } }]
  CustomerId,
  
  _Customer.last_name as CustomerName,
  
  BeginDate,
  
  EndDate,
  
  @Semantics.amount.currencyCode: 'CurrencyCode'
  BookingFee,
  
  @Semantics.amount.currencyCode: 'CurrencyCode'
  TotalPrice,
  
  @Consumption.valueHelpDefinition: [{ 
                      entity: { name: 'I_CURRENCY',
                                element: 'CURRENCY' } }]
  @Semantics.currencyCode: true                              
  CurrencyCode,
  
  Description,
  
  Status,
  
  @Semantics.user.createdBy: true
  CreatedBy,
  
  @Semantics.systemDateTime.createdAt: true
  CreatedAt,
  
  @Semantics.user.lastChangedBy: true
  LastChangedBy,
  
  @Semantics.systemDateTime.lastChangedAt: true
  LastChangedAt,
  
  
  /* Associations */
  _Agency,
  _Booking : redirected to composition child ZC_SHW_RAP_U_BOOKING,
  _Currency,
  _Customer
}
