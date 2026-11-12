# SAT – SAS CDS Raporu

Açık ve kapalı tüm SAS kalemlerini SAT bilgileri, mal girişi/fatura durumu ve fatura tutarı (TRY + belge para birimi) ile listeler.
Dosyalar `SAS_CDS_` önekiyle kökte durur; istenirse bir klasöre taşınabilir.

| Dosya | Açıklama |
|---|---|
| `SAS_CDS_ZI_SAS_EKBE_TUTAR.asddls` | EKBE (E/Q) satırları, işaretli tutar, `currency_conversion` ile TRY |
| `SAS_CDS_ZI_SAS_EKBE_OZET.asddls` | Kalem bazında mal girişi/fatura adedi ve fatura toplamları (aggregate) |
| `SAS_CDS_ZC_SAS_RAPOR.asddls` | Ana rapor view'i (EKPO, EKKO, EBAN, MAKT + özet) |
| `SAS_CDS_ALV.abap` | Basit ALV raporu (ZSAS_RAPOR_ALV) |

Aktivasyon sırası: TUTAR → OZET → RAPOR. View adları (ZI_/ZC_) dosya adlarından bağımsızdır.

## Varsayımlar
- **S/4HANA 2023 (S4CORE 108, SAP_BASIS 758):** `I_*API01` view'ları sistemde yok; bu yüzden **doğrudan tablolardan** (EKPO, EKKO, EBAN, EKBE, MAKT) okunur. ABAP CDS view entity, `currency_conversion`, `dats_days_between` kullanılır.
- **SAT onay tarihi:** `EBAN-FRGDT`; yoksa gün farkı NULL.
- **SAS yaratma tarihi:** `EKKO-AEDAT`. **Gün farkı** = SAS yaratma − SAT onay (negatif olabilir).
- **SAT bağlantısı:** `EKPO-BANFN/BNFPO` (SAT'sız SAS de listelenir).
- **Mal girişi:** EKBE `BEWTP='E'` varsa `X`. **Fatura girişi:** `BEWTP='Q'` varsa `X`; iptaller (`SHKZG='H'`) negatif.
- **Fatura tutarı:** `EKBE-WRBTR`; TRY için kur tipi `M`, kur tarihi `BUDAT`, kur yoksa NULL.
- **Kontrol kodu:** Belirsiz; `EKPO-STEUC` varsayıldı, `ZC_SAS_RAPOR`'da değiştirilebilir.
- **Para birimi:** `EKKO-WAERS`; SAT tutarı `EBAN-RLWRT`, para birimi `EBAN-WAERS`.
- **Açık/kapalı:** filtre yok; `TeslimTamamlandi` (ELIKZ) ve `SilmeGostergesi` (LOEKZ) ile ayrışır.
- **Performans:** EKBE toplamları ve TRY dönüşümü ayrı aggregate view'da (`ZI_SAS_EKBE_OZET`) kalem bazında önceden hesaplanır; ana view'de 4 join vardır. Rapora SAS no/tarih filtresi verin.
- Yetki kontrolü yok (`#NOT_REQUIRED`); kod bir sistemde derlenmedi.
