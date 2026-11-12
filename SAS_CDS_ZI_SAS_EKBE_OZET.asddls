@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS kalemi mal girişi / fatura özeti'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_OZET
  as select from ZI_SAS_EKBE_TUTAR
{
  key SasNo,
  key SasKalem,
      BelgePB,

      sum( case HistTipi when 'E' then 1 else 0 end ) as MalGirisiAdet,
      sum( case HistTipi when 'Q' then 1 else 0 end ) as FaturaAdet,

      @Semantics.amount.currencyCode: 'BelgePB'
      sum( case HistTipi when 'Q' then TutarBelgePB else cast( 0 as abap.curr(13,2) ) end ) as FaturaTutarBelgePB,

      @Semantics.amount.currencyCode: 'TryPB'
      sum( case HistTipi when 'Q' then TutarTRY else cast( 0 as abap.curr(13,2) ) end ) as FaturaTutarTRY,

      TryPB
}
group by
  SasNo,
  SasKalem,
  BelgePB,
  TryPB
