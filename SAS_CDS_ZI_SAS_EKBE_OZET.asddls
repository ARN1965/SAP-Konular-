@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS kalemi mal girişi / fatura özeti (kalem başına tek satır)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_OZET
  as select from ZI_SAS_EKBE_TUTAR
{
  key ebeln,
  key ebelp,

      // Net adet > 0 ise gerçekleşmiş (iptaller düşülür)
      sum( case bewtp when 'E' then net_adet else 0 end ) as mal_girisi_net,
      sum( case bewtp when 'Q' then net_adet else 0 end ) as fatura_net,

      po_pb,
      @Semantics.amount.currencyCode: 'po_pb'
      sum( case bewtp when 'Q' then tutar_po_pb else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_po_pb,

      try_pb,
      @Semantics.amount.currencyCode: 'try_pb'
      sum( case bewtp when 'Q' then tutar_try else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_try,

      kokrs_pb,
      @Semantics.amount.currencyCode: 'kokrs_pb'
      sum( case bewtp when 'Q' then tutar_kokrs else cast( 0 as abap.curr(13,2) ) end ) as fatura_tutar_kokrs
}
group by
  ebeln,
  ebelp,
  po_pb,
  try_pb,
  kokrs_pb
