@EndUserText.label: 'Consumption view for SHW RAP Travel'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TravelID']
define root view entity ZC_SHW_RAP_TRAVEL 
        as projection on ZI_SHW_RAP_TRAVEL as Travel {
        
  key TravelUuid,
  
  @Search.defaultSearchElement: true
  TravelId,
  
  @Search.defaultSearchElement: true
//  @ObjectModel.text.element: ['AgencyName']
  @Consumption.valueHelpDefinition: [{ 
                      entity: { name: '/DMO/I_AGENCY',
                                element: 'AgencyID' } }]
  AgencyId,
  
  _Agency.Name as AgencyName,
  
  @Search.defaultSearchElement: true
  @ObjectModel.text.element: ['CustomerName']
  @Consumption.valueHelpDefinition: [{ 
                      entity: { name: '/DMO/I_CUSTOMER',
                                element: 'CustomerID' } }]
  CustomerId,
  
  _Customer.LastName as CustomerName,
  
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
  
  TravelStatus,
  
  @Semantics.user.createdBy: true
  CreatedBy,
  
  @Semantics.systemDateTime.createdAt: true
  CreatedAt,
  
  @Semantics.user.lastChangedBy: true
  LastChangedBy,
  
  @Semantics.systemDateTime.lastChangedAt: true
  LastChangedAt,
  
  
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  LocalLastChangedAt,
  /* Associations */
  _Agency,
  _Booking : redirected to composition child ZC_SHW_RAP_BOOKING,
  _Currency,
  _Customer
  
}
