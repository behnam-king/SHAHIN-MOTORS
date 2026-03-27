شاهین موتور - پچ CRM / ثبت‌نام / لید

فایل‌های این پچ:
- crm/customer_sync.py
- crm/models.py
- crm/signals.py
- crm/views.py
- crm/migrations/0004_customer_nullable_phone_and_names.py
- catalog/forms.py
- catalog/views.py
- templates/catalog/auth.html
- templates/catalog/register.html

کاری که این پچ انجام می‌دهد:
1) رفع خطای ثبت‌نام ناشی از Customer.phone
2) ساخت امن Customer برای کاربران جدید و قدیمی
3) افزودن شماره موبایل به فرم ثبت‌نام
4) تبدیل فرم تماس سایت به Lead واقعی در CRM
5) ساخت Interaction و Task خودکار برای لید جدید
6) همگام‌سازی پایه‌ای Customer با سفارش‌ها

مراحل اعمال:
1) از پروژه فعلی خود بکاپ بگیر.
2) فایل‌های داخل این zip را روی ریشه پروژه Django خود کپی و جایگزین کن.
3) در ریشه پروژه این دستورها را اجرا کن:
   python manage.py migrate
   python manage.py check
4) پروژه را اجرا و تست کن.

تست‌های پیشنهادی:
- ثبت‌نام کاربر جدید با شماره موبایل
- ورود به /crm/dashboard/
- ارسال فرم /contact/
- بررسی Django Admin > CRM > Leads / Tasks / Interactions
