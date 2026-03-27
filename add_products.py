
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shahinmotor_site.settings')
django.setup()

from catalog.models import Brand, MotorcycleCategory, Motorcycle

# --- 1. Brands Setup ---
brands_data = [
    {'name_fa': 'لیفان', 'name_en': 'Lifan', 'slug': 'lifan'},
    {'name_fa': 'دلتا', 'name_en': 'Delta', 'slug': 'delta'},
]

brand_objects = {}
for b_data in brands_data:
    brand, created = Brand.objects.get_or_create(
        slug=b_data['slug'],
        defaults={
            'name_fa': b_data['name_fa'],
            'name_en': b_data['name_en'],
            'description': f"محصولات موتورسیکلت {b_data['name_fa']}",
            'is_active': True
        }
    )
    brand_objects[b_data['slug']] = brand
    if created:
        print(f"Brand created: {brand.name_fa}")
    else:
        print(f"Brand exists: {brand.name_fa}")

# --- 2. Categories Setup ---
# بر اساس نام محصولات، دسته‌بندی‌های احتمالی را حدس می‌زنیم یا عمومی در نظر می‌گیریم
# اگر دسته‌بندی خاصی مد نظر نیست، همه را در یک دسته یا دسته‌های موجود می‌ریزیم.
# اینجا چند دسته کلی ایجاد می‌کنیم.
categories_data = [
    {'name': 'استریت', 'slug': 'street'},
    {'name': 'اسکوتر', 'slug': 'scooter'},
    {'name': 'ترید', 'slug': 'trail'},
    {'name': 'رالی', 'slug': 'rally'},
    {'name': 'برقی', 'slug': 'electric'},
    {'name': 'کاب', 'slug': 'cub'}, # برای مدل‌های طرح ویو یا کاب
]

category_objects = {}
for c_data in categories_data:
    cat, created = MotorcycleCategory.objects.get_or_create(
        slug=c_data['slug'],
        defaults={
            'name': c_data['name'],
            'is_active': True
        }
    )
    category_objects[c_data['slug']] = cat

# --- 3. Products Data ---
# لیست محصولات ورودی کاربر
# سعی می‌کنیم مشخصات فنی را از نام استخراج کنیم (cc, watt)
products_list = [
    "LIFAN KPS 250 cc",
    "DELTA TRAIL 250 cc",
    "DELTA RALLY 250 cc",
    "DELTA AC4 250 cc",
    "LIFAN KPS 200 cc",
    "LIFAN KPV s 150 cc",
    "LIFAN KPV 150 cc",
    "LIFAN PK 135 cc",
    "LIFAN BM 180 cc",
    "DELTA RX 170 cc",
    "DELTA RX 155cc water",
    "DELTA VSP 170cc sport",
    "DELTA VSP 170cc sprint",
    "DELTA VSP 170cc classic",
    "DELTA Click 170 cc",
    "DELTA Click 150cc water",
    "DELTA Click 150 cc",
    "LIFAN CDI 125-150-200 cc", # این مورد چند مدل است، جدا می‌کنیم یا یک مدل کلی؟ فعلا یک مدل کلی با توضیح
    "DELTA CRT 160 cc",
    "LIFAN CTS 125 cc",
    "DELTA G5 2300w",
    "DELTA Z3 1800w",
    "DELTA YD 1500w",
]

# تابع کمکی برای تشخیص دسته
def detect_category(name):
    name_lower = name.lower()
    if 'scooter' in name_lower or 'vsp' in name_lower or 'click' in name_lower or 'kpv' in name_lower:
        return category_objects.get('scooter')
    if 'trail' in name_lower or 'crt' in name_lower:
        return category_objects.get('trail')
    if 'rally' in name_lower:
        return category_objects.get('rally')
    if 'w' in name_lower and ('2300' in name_lower or '1800' in name_lower or '1500' in name_lower):
        return category_objects.get('electric')
    if 'cdi' in name_lower or 'pk' in name_lower or 'bm' in name_lower or 'cts' in name_lower:
        return category_objects.get('cub') # یا عمومی
    return category_objects.get('street') # پیش‌فرض

import re

for p_name in products_list:
    # تمیزکاری نام
    clean_name = p_name.strip()
    
    # تشخیص برند
    brand = None
    if 'LIFAN' in clean_name.upper():
        brand = brand_objects['lifan']
    elif 'DELTA' in clean_name.upper():
        brand = brand_objects['delta']
    else:
        # پیش‌فرض اگر برند در نام نبود (که در لیست بالا همه دارند)
        continue

    # استخراج حجم موتور یا توان
    engine_cc = 0
    power = ""
    
    # جستجوی cc
    cc_match = re.search(r'(\d+)\s*cc', clean_name, re.IGNORECASE)
    if cc_match:
        engine_cc = int(cc_match.group(1))
    
    # جستجوی watt
    watt_match = re.search(r'(\d+)\s*w', clean_name, re.IGNORECASE)
    if watt_match:
        power = f"{watt_match.group(1)} وات"
        engine_cc = 0 # برای برقی‌ها معمولا 0 یا معادل می‌زنند، اینجا 0 می‌گذاریم
    elif engine_cc > 0:
        power = f"{engine_cc} سی‌سی"

    # تولید اسلاگ
    slug = clean_name.lower().replace(' ', '-').replace('cc', '').replace('water', '-water').strip('-')
    # جلوگیری از اسلاگ تکراری (ساده)
    original_slug = slug
    counter = 1
    while Motorcycle.objects.filter(slug=slug).exists():
        slug = f"{original_slug}-{counter}"
        counter += 1

    # دسته بندی
    category = detect_category(clean_name)
    
    # توضیحات
    desc = f"موتورسیکلت {clean_name} محصول شرکت شاهین موتور."
    if 'water' in clean_name.lower():
        desc += " سیستم خنک‌کننده آب خنک."
    
    # ایجاد محصول
    product, created = Motorcycle.objects.get_or_create(
        title=clean_name,
        defaults={
            'slug': slug,
            'brand': brand,
            'category': category,
            'engine_cc': engine_cc,
            'power': power,
            'short_description': desc,
            'full_description': desc,
            'price': 0, # قیمت فعلا 0
            'status': 'new', # وضعیت جدید
            'is_active': True,
            'show_price': False # قیمت را نمایش نده
        }
    )
    
    if created:
        print(f"Product created: {clean_name}")
    else:
        print(f"Product exists: {clean_name}")

print("All products processed.")
