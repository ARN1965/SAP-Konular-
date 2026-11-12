@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS kalemi mal girişi / fatura özeti'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_OZET
  as select from ZI_SAS_EKBE_TUTAR
{
  key ebeln,
  key ebelp,
      waers,

      sum( case bewtp when 'E' then 1 else 0 end ) as mal_girisi_adet,
      sum( case bewtp when 'Q' then 1 else 0 end ) as fatura_adet,

      @Semantics.amount.currencyCode: 'waers'
      sum( case bewtp when 'Q' then tutar_belge_pb else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_belge_pb,

      @Semantics.amount.currencyCode: 'try_pb'
      sum( case bewtp when 'Q' then tutar_try else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_try,

      @Semantics.amount.currencyCode: 'kokrs_pb'
      sum( case bewtp when 'Q' then tutar_kokrs else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_kokrs,

      try_pb,
      kokrs_pb
}
group by
  ebeln,
  ebelp,
  waers,
  try_pb,
  kokrs_pb
