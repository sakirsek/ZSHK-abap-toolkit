# CLAUDE.md — ZSHK ABAP Toolkit

Kişisel, taşınabilir ABAP utility toolkit'i. Şirketten bağımsız, abapGit ile herhangi bir SAP sistemine çekilebilir.

## Proje bilgileri

| Alan | Değer |
|---|---|
| **Paket** | `ZSHK` |
| **Prefix** | `ZSHK` — Shakur mahlası, `Z` namespace |
| **GitHub** | https://github.com/sakirsek/ZSHK-abap-toolkit |
| **Lisans** | MIT |
| **Min. ABAP** | 7.50+ (S/4HANA uyumlu) |
| **Bağımlılık** | Sıfır — sadece SAP standart sınıf/FM |

## İsimlendirme kuralları

```
ZCL_SHK_<MODUL>     → Sınıflar        (ör: ZCL_SHK_LOG, ZCL_SHK_MAIL)
ZIF_SHK_<MODUL>     → Arayüzler       (ör: ZIF_SHK_LOG)
ZCX_SHK_<MODUL>     → Exception'lar   (ör: ZCX_SHK_LOG)
ZSHK_S_<YAPI>       → Structure'lar
ZSHK_T_<TABLO>      → Table type'lar
```

## SAP hedef sistem (NED) — geliştirme ortamı

| Alan | Değer |
|---|---|
| **Sistem** | SAP NetWeaver 7.51 SP02, on-prem (HANA DB) |
| **Host** | `10.251.33.41:8000`, client `200`, user `SAKIRS` |
| **Transport prefix** | `NEDK…` |
| **abapGit** | Standalone (`ZABAPGIT`) + ADT Backend (`$ABAPGIT_ADT`) |
| **abapGit repo key** | `000000000012` |

## Geliştirme iş akışı

### Kod yazma
Claude, `arc-1` MCP server üzerinden `SAPWrite` ile doğrudan SAP'da kod yazar ve `SAPActivate` ile aktive eder. Tüm nesneler tek bir transport request altında tutulur.

### Transport kuralı
`SHK: <ShortPurpose>` — CLAUDE.md'deki NURSAN-ABAP transport naming convention'a uygun (Z harfi düşürülür).

### Git push (SAP → GitHub)
**arc-1 MCP üzerinden push çalışmıyor** — abapGit ADT bridge stage endpoint'i boş dönüyor (NED'deki ADT Backend versiyonunun sınırlaması). Push, kullanıcı tarafından ZABAPGIT GUI'den yapılır:
1. SE38 → `ZABAPGIT` çalıştır
2. ZSHK repo'sunu aç
3. Stage → commit mesajı yaz → push
4. GitHub user: `sakir.sek@gmail.com`, token: fine-grained PAT (repo scope)

### Git pull (GitHub → SAP)
Yeni bir sisteme kurulum: ZABAPGIT'ten `https://github.com/sakirsek/ZSHK-abap-toolkit.git` clone → ZSHK paketi oluştur → pull.

## Mimari ilkeler

1. **Sıfır harici bağımlılık** — sadece SAP standart. Addict/Simbal gibi zincir yapma
2. **Her sınıf bağımsız çalışır** — bir sınıfı almak için başka bir sınıfı çekmek zorunda kalınmamalı
3. **Multiton + lazy init** — aynı key ile tekrar sorgu yapma, önbellekten dön (Addict'ten ilham)
4. **Interface-first** — her modülde `ZIF_SHK_*` arayüzü, mock ile test edilebilirlik
5. **Az exception** — alan başına 1 genel exception yeter, 22 tane yazma
6. **Sadece acı veren yerleri sar** — SAP standardı yeterliyse (CL_SALV_TABLE gibi) wrapper yapma
7. **3x kuralı** — bir pattern'i 3. kez kopyala-yapıştır yaparken toolkit'e al, daha önce değil

## Modül planı

### Öncelik 1 — kesin yapılacak

| Modül | Sınıf(lar) | Açıklama | Durum |
|---|---|---|---|
| **Log** | `ZCL_SHK_LOG`, `ZCL_SHK_LOG_GUI`, `ZIF_SHK_LOG`, `ZCX_SHK_LOG` | BAL_* wrapper: add_bapiret2/add_exception/add_sy_msg/add_free_text → save → display. Simbal API tasarımından ilham | Sırada |
| **Mail** | `ZCL_SHK_MAIL` | CL_BCS wrapper: HTML body, ek (PDF/Excel/CSV), CC/BCC, dağıtım listesi | Planlandı |
| **FTP** | `ZCL_SHK_FTP` | Upload/download, dizin listeleme, hata yönetimi | Planlandı |
| **HTTP** | `ZCL_SHK_HTTP` | REST client: GET/POST/PUT/DELETE, JSON parse, timeout, Türkçe karakter | Planlandı |
| **BDC** | `ZCL_SHK_BDC` | CALL TRANSACTION wrapper: ekran/alan ekleme, hata dönüşü BAPIRET2 | Planlandı |
| **Excel** | `ZCL_SHK_EXCEL` | İç tablo → XLSX üretme, mail'e ek olarak ekleme | Planlandı |

### Öncelik 2 — muhtemelen yapılacak

| Modül | Açıklama |
|---|---|
| **Job** | Arka plan job başlatma, tekil job kilidi, paralel çalıştırma |
| **Date** | Fabrika takvimi, iş günü kontrolü, dönem dönüşümü |
| **Progress** | İlerleme çubuğu, kalan süre tahmini |
| **Return** | BAPIRET2 üretme, SY-MSG dönüştürme, mesaj toplama |
| **CSV** | İç tablo ↔ CSV, Türkçe karakter/separator |
| **PDF** | Smartform → binary PDF dönüşümü |

### Yapılmayacak

- ALV tam sarma (CL_SALV_TABLE yeterli)
- Fonksiyonel modül sınıfları (MM material, SD customer — şirkete bağlı)
- DDIC okuyucu (SAP standardı yeterli)
- Transport yönetimi, Workflow (niş)

## Referans repolar (ilham kaynağı)

| Repo | Ne aldık | Ne almadık |
|---|---|---|
| `keremkoseoglu/ABAP-Library` (298★) | Genel kapsam fikri | Harici bağımlılık zinciri, fonksiyonel modül sınıfları |
| `keremkoseoglu/Simbal` | BAL log API tasarımı (add_* → save → show) | — |
| `keremkoseoglu/addict` | Multiton/lazy init pattern | 37 sınıf + 22 exception (over-engineering) |
| `keremkoseoglu/ticksys` | Strategy pattern (interface-based) | Jira'ya özgü, kapsam dışı |

## MCP ile çalışma notları

- `SAPWrite` → sınıf/arayüz/exception oluşturma ve güncelleme
- `SAPActivate` → aktivasyon
- `SAPRead` → kaynak kod okuma
- `SAPTransport` → transport oluşturma (convention: `SHK: <purpose>`)
- `SAPGit stage/push` → **çalışmıyor** (ADT bridge sınırlaması), ZABAPGIT GUI kullan
- `SAPDiagnose action=unittest` → unit test çalıştırma (sadece hızlı testler, timeout riski)

## Mevcut durum

- ZSHK paketi SAP'da oluşturuldu
- abapGit ile GitHub repo'ya bağlandı (repo key: `000000000012`)
- DEVC (paket tanımı) GitHub'a pushlandı
- `ZCL_SHK_TEST` test sınıfı SAP'da var, henüz pushlanmadı
- Transport: `NEDK928959` (SHK: Initial package setup)
- İlk geliştirme modülü: **Log**
