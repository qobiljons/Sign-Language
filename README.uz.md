# Imo-Ishora Tilini Tovushga Aylantirish (0-9)

Bu loyiha **veb-kamera** orqali qo'l bilan ko'rsatilgan **0 dan 9 gacha** raqamlarni tanib oladi va ularni **o'zbek tilida ovoz chiqarib aytib beradi**.

Masalan: kameraga 5 sonini ishora qilsangiz, kompyuter "besh" deb gapiradi.

---

## Loyiha qanday ishlaydi (oddiy tilda)

Tasavvur qiling, bu loyiha 4 bosqichda ishlaydi:

1. **Kamera** — sizning qo'lingizni ko'radi.
2. **MediaPipe** (Google'ning kutubxonasi) — qo'lingizdagi 21 ta nuqtani topadi (har bir bo'g'in joyini).
3. **Sun'iy intellekt modeli** (kichkina neyron tarmoq) — bu nuqtalarga qarab "bu qaysi raqam?" deb javob beradi.
4. **Ovoz** — javobni o'zbekcha aytib beradi.

Bularning hammasi har soniyada o'nlab marta takrorlanadi, shuning uchun jonli ko'rinadi.

---

## Papkalar nima uchun kerak

### `audio/uzbek/`
Bu yerda **0 dan 9 gacha o'zbekcha aytiladigan ovoz fayllari** turadi.

```
0.m4a  → "nol"
1.m4a  → "bir"
2.m4a  → "ikki"
...
9.m4a  → "to'qqiz"
```

Dastur raqamni topgach, mos faylni ochib, kolonkalardan eshittiradi.

> Maslahat: o'z ovozingizni yozib qo'ymoqchi bo'lsangiz — shu papkadagi fayllarni almashtirsangiz bo'ladi. Asosiysi nomlari `0.m4a`, `1.m4a` shaklida bo'lishi.

---

### `commands/`
Bu yerda **ikkita "tugma" fayl** bor — ularga ikki marta bosib loyihani ishga tushirsangiz bo'ladi.

- **`setup.command`** — birinchi marta ishga tushiriladi. U:
  1. Python 3.11 ni topadi (yoki Windows'da yangi joydan o'rnatadi).
  2. Kerakli kutubxonalarni yuklaydi (mediapipe, opencv, torch va h.k.).
  3. Internet'dan ma'lumotlar to'plamini yuklab oladi (qo'l rasmlari).
  4. Modelni o'qitadi (kompyuter "raqamlarni tanishni" o'rganadi).
  
  Bularning hammasi avtomatik bo'ladi — siz faqat fayl ustiga ikki marta bosishingiz kerak.

- **`run.command`** — har safar dasturni ishga tushirish uchun. Kamera ochiladi va siz qo'lingizni ko'rsata boshlaysiz.

> Eslatma: setup faqat bir marta kerak. Keyin har doim run'ni ishlatasiz.

---

### `data/numbers/`
Bu yerda **modelni o'qitish uchun rasmlar** turadi. Har bir raqam uchun alohida papka:

```
data/numbers/0/   → 0 ishorasining yuzlab rasmlari
data/numbers/1/   → 1 ishorasining yuzlab rasmlari
...
data/numbers/9/   → 9 ishorasining yuzlab rasmlari
```

Bu rasmlar **Turk imo-ishora tili** (Türk İşaret Dili) ma'lumotlar to'plamidan kelgan — bepul va internetda mavjud. `setup.command` ularni o'zi yuklab oladi, sizdan hech narsa talab etilmaydi.

> Bu papkani siz qo'lda tahrirlamaysiz. Agar buzilib qolsa, shunchaki o'chirib `setup.command`ni qaytadan ishga tushirsangiz qaytadan paydo bo'ladi.

---

### `data/hand_poses_public/`
Bu yerda **rasmlar emas, raqamli ma'lumotlar** saqlanadi. Aniqrog'i:

- `X.npy` — har bir rasmdagi qo'l nuqtalari (21 ta nuqta × 3 koordinata = 63 ta raqam, har bir rasm uchun).
- `y.npy` — har bir rasmga tegishli javob (qaysi raqam ekanligi).

Bu fayllar `scripts/ingest.ipynb` tomonidan **bir marta** yaratiladi va keyin `train.ipynb` ulardan modelni o'qitishda foydalanadi.

> Tasavvur qiling: rasm 200 KB, lekin undan kerakli ma'lumot — atigi 63 ta raqam. Shuning uchun rasmlardan bir marta "siqib olamiz" va keyin tezroq ishlaymiz.

---

### `models/`
Bu yerda **o'qitilgan model** saqlanadi:

```
digits_mlp.pth   → modelning "miyasi" — qaysi nuqta qaysi raqamni anglatishi haqida bilim
```

`MLP` degani **Multi-Layer Perceptron** — sun'iy neyron tarmoqning eng oddiy turi. Bizniki juda kichkina:
- **Kirish:** 63 ta raqam (qo'l nuqtalari)
- **Ichki qatlamlar:** 128 → 128 ta neyron
- **Chiqish:** 10 ta raqam (har biri 0...9 ishorasi uchun "qanchalik ehtimoli bor")

Eng katta ehtimoli bor raqam — javob bo'ladi.

> Bu fayl `train.ipynb` tomonidan yaratiladi. Agar o'chirilib qolsa, `setup.command` qaytadan o'qitib beradi (taxminan 1-2 daqiqa).

---

### `scripts/`
Bu yerda **3 ta Jupyter daftarcha** (`.ipynb` fayl) — loyihaning aqli shu yerda:

- **`ingest.ipynb`** — "Yig'ish" daftarchasi.  
  Vazifasi: `data/numbers/` ichidagi har bir rasmni ochib, MediaPipe orqali qo'l nuqtalarini chiqarib oladi va `data/hand_poses_public/`ga yozadi.

- **`train.ipynb`** — "O'qitish" daftarchasi.  
  Vazifasi: yuqoridagi nuqtalarni olib, model'ni o'qitadi va `models/digits_mlp.pth`ga saqlaydi. Aslida bu yerda kompyuter "ko'rib o'rganadi".

- **`count.ipynb`** — "Sanoq" daftarchasi.  
  Vazifasi: kamerani ochadi, qo'lingizni har soniyada o'qiydi, model orqali raqamni topadi va `audio/uzbek/`dan ovozni eshittiradi. **Bu — siz haqiqatan ko'rib turadigan oyna.**

> Bu fayllarni Jupyter Notebook'da ham ochsa bo'ladi (kod va matnlarni ko'rish uchun), lekin `commands/`dagi fayllar ularni avtomatik ishga tushiradi — Jupyter o'rnatilmagan bo'lsa ham ishlaydi.

---

## Fayllar (papka emas)

### `README.md`
Ingliz tilidagi qisqacha tushuntirish.

### `README.uz.md`
Hozir o'qiyotgan fayl — o'zbek tilida tushuntirish.

### `.gitignore`
Git uchun ko'rsatma — qaysi fayllarni "saqlamasin" degan ro'yxat. Masalan, virtual muhit (`.venv/`) yoki yuklab olingan rasmlar — ularni hammaga qaytadan yuklamaslik kerak, har kim o'zi yuklab olsa bo'ladi.

### `.python_cmd`
Setup tomonidan yaratiladi. Ichida — qaysi Python ishlatish kerakligi yozilgan. `run.command` shu fayldan o'qib oladi.

---

## Birinchi marta qanday ishga tushirish

### Mac yoki Linux'da:
1. Terminal'ni oching.
2. Loyiha papkasiga kiring:
   ```bash
   cd ~/Desktop/Sign\ Language
   ```
3. O'rnatish:
   ```bash
   ./commands/setup.command
   ```
4. Ishga tushirish:
   ```bash
   ./commands/run.command
   ```

### Windows'da:
1. **Git Bash**'ni o'rnating ([git-scm.com](https://git-scm.com/download/win)) — bu PowerShell o'rniga bash buyruqlarini yozish imkonini beradi.
2. Git Bash'ni oching, papkaga kiring va yuqoridagi buyruqlarni yozing.

> Birinchi marta `setup.command` 5-15 daqiqa olishi mumkin — internet'dan kutubxonalar va rasmlar yuklanadi. Keyingi safar tezroq.

---

## Dastur ochilgach

Oynada quyidagilar ko'rinadi:

- **Yuqori chap burchak** — loyiha nomi, `Q` tugmasini bosib chiqish haqida eslatma.
- **Yuqori o'ng burchak** — "SCAN" paneli: u yerda topilgan raqam, o'zbekcha nomi va ishonch foizi (CONF) ko'rinadi.
- **Pastki o'ng burchak** — qizil "STOP" tugmasi (sichqoncha bilan bosib chiqish uchun).
- **Pastki chap burchak** — eng oxirgi tanilgan raqam katta yashil rangda.

### Qo'lingizni qanday ko'rsatish kerak

1. Qo'lingizni kameraga to'g'ri ushlang (juda yaqin emas, juda uzoq emas — taxminan 30-50 sm).
2. Raqamni ko'rsating va **bir-ikki soniya qo'zg'almasdan ushlab turing**.
3. Halqa to'lganida ovoz chiqaradi.
4. Boshqa raqamga o'tish uchun shunchaki ishorani o'zgartiring — qo'lingizni yashirish shart emas.
5. Chiqish uchun: STOP tugmasini bosing yoki klaviaturadan **Q** tugmasini bosing.

---

## Muammo bo'lsa

| Muammo | Yechim |
|---|---|
| Ovoz chiqmayapti | `audio/uzbek/` ichida `0.m4a`...`9.m4a` borligini tekshiring. Windows'da `setup.command`ni qaytadan ishga tushiring (avtomatik wav'ga o'giradi). |
| Kamera ochilmayapti | Boshqa dasturlar (Zoom, Teams) kamerani ishlatmayotganiga ishonch hosil qiling. |
| "Python 3.11 not found" | Mac: `brew install pyenv && pyenv install 3.11.9`. Windows: [python.org](https://www.python.org/downloads/release/python-3119/) — "Add to PATH" katakchasini belgilang. |
| Hech qanday raqam tanilmayapti | Yorug'lik yetarli ekanligini tekshiring. Qo'lingiz to'liq kadrga sig'sin. |

---

## Loyiha tarkibining qisqacha xaritasi

```
Sign Language/
├── audio/
│   └── uzbek/                    ← ovoz fayllari (0.m4a ... 9.m4a)
├── commands/
│   ├── setup.command             ← birinchi marta ishga tushirish
│   └── run.command               ← har safar ishga tushirish
├── data/
│   ├── numbers/                  ← qo'l rasmlari (0/, 1/, ... 9/)
│   └── hand_poses_public/        ← raqamga aylantirilgan ma'lumotlar
├── models/
│   └── digits_mlp.pth            ← o'qitilgan model
├── scripts/
│   ├── ingest.ipynb              ← rasmlarni o'qib, nuqtalarni chiqaradi
│   ├── train.ipynb               ← modelni o'qitadi
│   └── count.ipynb               ← jonli kamera + ovoz
├── README.md                     ← inglizcha qisqacha
├── README.uz.md                  ← shu fayl
└── .gitignore
```

Hammasi shu. Savol bo'lsa — kodga qarab ko'ring, har bir daftarchada izohlar bor.
