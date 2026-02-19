# سایت فروش موتورسیکلت شاهین موتور

یک وب‌سایت فروش موتورسیکلت با Django و HTML/CSS/JS (RTL) با طراحی الهام‌گرفته از Woodmart Motorcycle.

## ویژگی‌ها

- ✅ طراحی راست‌چین (RTL) و فارسی
- ✅ مدیریت محصولات، برندها، نمایندگی‌ها و مقالات
- ✅ سیستم فرم تماس و درخواست خرید
- ✅ فیلتر و جستجوی پیشرفته محصولات
- ✅ پنل مدیریت Django Admin
- ✅ طراحی ریسپانسیو و موبایل‌فرست
- ✅ بهینه‌سازی سئو

## نصب و راه‌اندازی

### پیش‌نیازها

- Python 3.8+
- pip

### مراحل نصب

1. فعال‌سازی محیط مجازی:
```bash
# Windows
.\venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

2. نصب وابستگی‌ها:
```bash
pip install -r requirements.txt
```

3. اجرای migrations:
```bash
python manage.py migrate
```

4. ایجاد کاربر ادمین:
```bash
python manage.py createsuperuser
```

5. اجرای سرور توسعه:
```bash
python manage.py runserver
```

سایت در آدرس `http://127.0.0.1:8000` در دسترس خواهد بود.

## ساختار پروژه

```
shahinMotor/
├── catalog/              # اپ اصلی
│   ├── models.py        # مدل‌های دیتابیس
│   ├── views.py         # ویوها
│   ├── urls.py          # URLها
│   ├── forms.py         # فرم‌ها
│   └── admin.py         # تنظیمات Admin
├── shahinmotor_site/     # تنظیمات پروژه
├── templates/           # قالب‌های HTML
│   ├── base.html
│   └── catalog/
├── static/              # فایل‌های استاتیک
│   ├── css/
│   ├── js/
│   └── images/
├── media/               # فایل‌های آپلود شده
└── manage.py
```

## استفاده از پنل مدیریت

برای دسترسی به پنل مدیریت:
1. به آدرس `http://127.0.0.1:8000/admin` بروید
2. با کاربر ادمین که ایجاد کردید وارد شوید
3. می‌توانید محصولات، برندها، نمایندگی‌ها و مقالات را مدیریت کنید

## صفحات اصلی

- `/` - صفحه اصلی
- `/products/` - لیست محصولات
- `/products/<slug>/` - جزئیات محصول
- `/brands/` - لیست برندها
- `/dealers/` - لیست نمایندگی‌ها
- `/articles/` - لیست مقالات/اخبار
- `/contact/` - تماس با ما
- `/about/` - درباره ما
- `/warranty/` - شرایط گارانتی
- `/services/` - خدمات پس از فروش

## نکات مهم

- فایل‌های تصویری در پوشه `media/` ذخیره می‌شوند
- برای تولید، باید `DEBUG = False` و تنظیمات `STATIC_ROOT` و `MEDIA_ROOT` را تنظیم کنید
- فونت Vazirmatn از Google Fonts لود می‌شود

## توسعه

برای افزودن ویژگی‌های جدید:
1. مدل‌های جدید را در `catalog/models.py` تعریف کنید
2. ویوها را در `catalog/views.py` اضافه کنید
3. URLها را در `catalog/urls.py` ثبت کنید
4. قالب‌های HTML را در `templates/catalog/` ایجاد کنید

## مجوز

این پروژه برای استفاده شخصی و تجاری آزاد است.

