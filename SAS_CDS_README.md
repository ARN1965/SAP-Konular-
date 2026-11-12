# SAT – SAS CDS Raporu

Açık ve kapalı tüm SAS kalemlerini SAT bilgileri, mal girişi/fatura durumu ve fatura tutarı (TRY + belge para birimi) ile listeler.
Dosyalar `SAS_CDS_` önekiyle kökte durur; istenirse `CDS-SAS-Raporu/` altına taşınabilir.

| Dosya | Açıklama |
|---|---|
| `SAS_CDS_ZI_SAS_EKBE_TUTAR.asddls` | EKBE (E/Q) satırları, işaretli tutar, `currency_conversion` ile TRY |
| `SAS_CDS_ZI_SAS_EKBE_OZET.asddls` | Kalem bazında mal girişi/fatura adedi ve fatura toplamları |
| `SAS_CDS_ZC_SAS_RAPOR.asddls` | Ana rapor view'i (EKPO, EKKO, EBAN, MAKT) |
| `SAS_CDS_ALV.abap` | Basit ALV raporu (ZSAS_RAPOR_ALV) |

Aktivasyon sırası: TUTAR → OZET → RAPOR. View adları (ZI_/ZC_) dosya adlarından bağımsızdır.

## Varsayımlar
- **Tablolara doğrudan erişim yoktur**; yayımlanmış (released) standart CDS view'lar okunur: `I_PurchaseOrderItemAPI01`, `I_PurchaseOrderAPI01`, `I_PurchaseRequisitionItemAPI01`, `I_PurchaseOrderHistoryAPI01`, `I_ProductDescription`.
- **S/4HANA 2020+** (view entity, `currency_conversion`, `dats_days_between`). Alan adları sürüme göre değişebilir; aktivasyonda ADT'de doğrulayın.
- **SAT onay tarihi:** `PurchaseRequisitionReleaseDate` (EBAN-FRGDT); yoksa gün farkı NULL.
- **SAS yaratma tarihi:** `I_PurchaseOrderAPI01.CreationDate` (EKKO-AEDAT). **Gün farkı** = SAS yaratma − SAT onay.
- **SAT bağlantısı:** SAS kalemindeki `PurchaseRequisition/Item` (SAT'sız SAS de listelenir).
- **SAT tutarı:** `RequestedQuantity × PurchaseRequisitionPrice / PurchasingPriceUnit` hesaplanır.
- **Mal girişi:** PO geçmişinde `PurchasingHistoryDocumentType='E'` varsa `X`. **Fatura girişi:** tip `'Q'` varsa `X`; alacak (`DebitCreditCode='H'`) negatif.
- **Fatura tutarı:** `InvoiceAmountInFrgnCurrency` (belge para birimi); TRY için kur tipi `M`, kur tarihi `PostingDate`, kur yoksa NULL.
- **Kontrol kodu:** Belirsiz; `ConsumptionTaxCtrlCode` (EKPO-STEUC) varsayıldı, `ZC_SAS_RAPOR`'da değiştirilebilir.
- **Para birimi:** SAS kalemi `DocumentCurrency`; SAT için `PurReqnItemCurrency`. SAS tutarı `NetAmount`.
- **Açık/kapalı:** filtre yok; `TeslimTamamlandi` (`IsCompletelyDelivered`) ve `SilmeGostergesi` ile ayrışır.
- **SAT tutarı** fiyat birimi 1 varsayılarak `miktar × fiyat` alınır.
- **Performans:** PO geçmişi (mal girişi/fatura) ve TRY dönüşümü `ZI_SAS_EKBE_*` içinde kalem bazında önceden toplanır; ana view yalnızca 5 join içerir (SAS kalemi, başlık, SAT kalemi, özet, ürün tanımı). Rapor view'ine her zaman SAS no/tarih filtresi verin; geçmiş yalnızca E/Q tipleriyle sınırlıdır.
- Yetki kontrolü yok (`#NOT_REQUIRED`); kod bir sistemde derlenmedi.
