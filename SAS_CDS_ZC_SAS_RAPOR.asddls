@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAT - SAS raporu (açık ve kapalı)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_SAS_RAPOR
  as select from I_PurchaseOrderItemAPI01 as poi
    inner join      I_PurchaseOrderAPI01 as po  on po.PurchaseOrder = poi.PurchaseOrder
    left outer join I_PurchaseRequisitionItemAPI01 as pri
                                                on  pri.PurchaseRequisition     = poi.PurchaseRequisition
                                                and pri.PurchaseRequisitionItem = poi.PurchaseRequisitionItem
    left outer join ZI_SAS_EKBE_OZET as ozet    on  ozet.SasNo    = poi.PurchaseOrder
                                                and ozet.SasKalem = poi.PurchaseOrderItem
    left outer join I_ProductDescription as pd  on  pd.Product  = poi.Material
                                                and pd.Language = $session.system_language
{
  key poi.PurchaseOrder                 as SasNo,
  key poi.PurchaseOrderItem             as SasKalem,

      poi.PurchaseRequisition           as SatNo,
      poi.PurchaseRequisitionItem       as SatKalem,
      poi.Material                      as Malzeme,
      // Tanım yoksa kalem kısa metni kullanılır
      coalesce( pd.ProductDescription, poi.PurchaseOrderItemText ) as MalzemeTanimi,

      // SAT miktarı ve tutarı (tutar = miktar x fiyat / fiyat birimi)
      pri.BaseUnit                      as SatBirim,
      @Semantics.quantity.unitOfMeasure: 'SatBirim'
      pri.RequestedQuantity             as SatMiktar,
      pri.PurReqnItemCurrency           as SatParaBirimi,
      // Fiyat birimi (PRICE UNIT) 1 kabul edilir; basit çarpım
      @Semantics.amount.currencyCode: 'SatParaBirimi'
      cast( pri.RequestedQuantity * pri.PurchaseRequisitionPrice as abap.curr(15,2) ) as SatTutar,

      // SAS miktarı ve tutarı
      poi.PurchaseOrderQuantityUnit     as SasBirim,
      @Semantics.quantity.unitOfMeasure: 'SasBirim'
      poi.OrderQuantity                 as SasMiktar,
      poi.DocumentCurrency              as ParaBirimi,
      @Semantics.amount.currencyCode: 'ParaBirimi'
      poi.NetAmount                     as SasTutar,

      // Tarihler
      pri.PurchaseRequisitionReleaseDate as SatOnayTarihi,
      po.CreationDate                   as SasYaratmaTarihi,
      case when pri.PurchaseRequisitionReleaseDate is null
             or pri.PurchaseRequisitionReleaseDate = '00000000'
           then cast( null as abap.int4 )
           else dats_days_between( pri.PurchaseRequisitionReleaseDate, po.CreationDate ) end as GunFarki,

      // Göstergeler
      case when ozet.MalGirisiAdet > 0 then 'X' else '' end as MalGirisiYapildi,
      case when ozet.FaturaAdet > 0    then 'X' else '' end as FaturaGirisiYapildi,

      // Fatura tutarı: belge para birimi ve TRY
      @Semantics.amount.currencyCode: 'ParaBirimi'
      ozet.FaturaTutarBelgePB           as FaturaTutarBelgePB,
      @Semantics.amount.currencyCode: 'FaturaParaBirimiTRY'
      ozet.FaturaTutarTRY               as FaturaTutarTRY,
      cast( 'TRY' as abap.cuky )        as FaturaParaBirimiTRY,

      // Kontrol kodu (varsayım: EKPO-STEUC = ConsumptionTaxCtrlCode)
      poi.ConsumptionTaxCtrlCode        as KontrolKodu,

      poi.PurchasingDocumentDeletionCode as SilmeGostergesi,
      poi.IsCompletelyDelivered         as TeslimTamamlandi
}
