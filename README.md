from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import sqlite3
from datetime import datetime, timedelta
import hashlib
import random
import threading
import time

app = Flask(__name__)
app.secret_key = 'your-secret-key-here-change-it-12345'

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def get_db():
    conn = sqlite3.connect('delivery_service.db')
    conn.row_factory = sqlite3.Row
    return conn

def init_database():
    """Создаёт все таблицы и заполняет их тестовыми данными"""
    conn = get_db()
    cursor = conn.cursor()
    
    # Проверяем, есть ли уже таблицы
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='товары'")
    if cursor.fetchone():
        conn.close()
        return
    
    # Создание всех таблиц
    cursor.execute('''
    CREATE TABLE курьеры (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        имя TEXT NOT NULL,
        фамилия TEXT NOT NULL,
        телефон TEXT NOT NULL,
        email TEXT,
        статус TEXT DEFAULT 'active',
        транспорт TEXT,
        рейтинг REAL DEFAULT 5.0,
        дата_найма TEXT DEFAULT CURRENT_TIMESTAMP,
        занятость INTEGER DEFAULT 0
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE клиенты (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        имя TEXT NOT NULL,
        фамилия TEXT NOT NULL,
        телефон TEXT NOT NULL,
        email TEXT,
        адрес TEXT,
        бонусы INTEGER DEFAULT 0,
        дата_регистрации TEXT DEFAULT CURRENT_TIMESTAMP,
        категория TEXT DEFAULT 'обычный'
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE товары (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        название TEXT NOT NULL,
        описание TEXT,
        цена REAL NOT NULL,
        вес REAL,
        категория TEXT,
        наличие INTEGER DEFAULT 0,
        рейтинг REAL DEFAULT 0,
        дата_добавления TEXT DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE заказы (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        клиент_id INTEGER NOT NULL,
        курьер_id INTEGER,
        дата_заказа TEXT DEFAULT CURRENT_TIMESTAMP,
        дата_доставки TEXT,
        статус TEXT DEFAULT 'pending',
        сумма REAL NOT NULL,
        способ_оплаты TEXT DEFAULT 'cash',
        примечания TEXT,
        FOREIGN KEY (клиент_id) REFERENCES клиенты(id),
        FOREIGN KEY (курьер_id) REFERENCES курьеры(id)
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE состав_заказа (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        заказ_id INTEGER NOT NULL,
        товар_id INTEGER NOT NULL,
        количество INTEGER DEFAULT 1,
        цена_в_момент_заказа REAL NOT NULL,
        FOREIGN KEY (заказ_id) REFERENCES заказы(id),
        FOREIGN KEY (товар_id) REFERENCES товары(id)
    )
    ''')
    
    # Добавление тестовых данных - Курьеры
    курьеры = [
        ('Иван', 'Петров', '+7(999)123-45-67', 'ivan@mail.ru', 'active', 'автомобиль', 4.8, 0),
        ('Мария', 'Иванова', '+7(999)234-56-78', 'maria@mail.ru', 'active', 'велосипед', 4.9, 0),
        ('Петр', 'Сидоров', '+7(999)345-67-89', 'petr@mail.ru', 'active', 'мотоцикл', 4.7, 0),
        ('Анна', 'Козлова', '+7(999)456-78-90', 'anna@mail.ru', 'active', 'пешком', 5.0, 0),
        ('Дмитрий', 'Соколов', '+7(999)567-89-01', 'dmitry@mail.ru', 'active', 'автомобиль', 4.6, 0),
        ('Елена', 'Морозова', '+7(999)678-90-12', 'elena@mail.ru', 'active', 'велосипед', 4.8, 0),
        ('Александр', 'Волков', '+7(999)789-01-23', 'alex@mail.ru', 'active', 'мотоцикл', 4.5, 0),
        ('Ольга', 'Павлова', '+7(999)890-12-34', 'olga@mail.ru', 'active', 'пешком', 4.9, 0),
        ('Сергей', 'Николаев', '+7(999)901-23-45', 'sergey@mail.ru', 'active', 'автомобиль', 4.7, 0),
        ('Наталья', 'Федорова', '+7(999)012-34-56', 'natalia@mail.ru', 'active', 'велосипед', 4.8, 0)
    ]
    
    cursor.executemany('''
        INSERT INTO курьеры (имя, фамилия, телефон, email, статус, транспорт, рейтинг, занятость) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', курьеры)
    
    # Клиенты
    клиенты = [
        ('Алексей', 'Смирнов', '+7(999)567-89-01', 'alexey@mail.ru', 'ул. Ленина, 10, кв. 5', 150, 'постоянный'),
        ('Елена', 'Кузнецова', '+7(999)678-90-12', 'elena.k@mail.ru', 'пр. Мира, 25, кв. 12', 75, 'обычный'),
        ('Дмитрий', 'Попов', '+7(999)789-01-23', 'dmitry.p@mail.ru', 'ул. Гагарина, 3, кв. 8', 200, 'VIP'),
        ('Ольга', 'Васильева', '+7(999)890-12-34', 'olga.v@mail.ru', 'ул. Пушкина, 15, кв. 3', 50, 'обычный'),
        ('Михаил', 'Новиков', '+7(999)901-23-45', 'mikhail@mail.ru', 'ул. Советская, 7, кв. 15', 300, 'VIP'),
    ]
    
    cursor.executemany('''
        INSERT INTO клиенты (имя, фамилия, телефон, email, адрес, бонусы, категория) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', клиенты)
    
    # Товары
    товары = [
        ('Пицца Маргарита', 'Классическая пицца с томатами и сыром', 450.00, 0.5, 'Еда', 50, 4.5),
        ('Роллы Филадельфия', 'С лососем, сливочным сыром и огурцом', 650.00, 0.3, 'Еда', 30, 4.8),
        ('Бургер Гурман', 'С двумя котлетами и трюфельным соусом', 380.00, 0.4, 'Еда', 25, 4.6),
        ('Салат Цезарь', 'С курицей и пармезаном', 320.00, 0.3, 'Еда', 20, 4.4),
        ('Кока-кола 1л', 'Напиток газированный', 120.00, 1.0, 'Напитки', 100, 4.2),
        ('Сок апельсиновый', 'Свежевыжатый', 180.00, 0.5, 'Напитки', 40, 4.7),
        ('Тирамису', 'Итальянский десерт', 280.00, 0.2, 'Десерты', 15, 4.9),
        ('Чизкейк Нью-Йорк', 'Классический чизкейк', 250.00, 0.2, 'Десерты', 20, 4.8),
        ('Картошка фри', 'С соусом', 150.00, 0.2, 'Закуски', 60, 4.3),
        ('Наггетсы', 'Куриные с соусом', 200.00, 0.25, 'Закуски', 45, 4.5)
    ]
    
    cursor.executemany('''
        INSERT INTO товары (название, описание, цена, вес, категория, наличие, рейтинг) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', товары)
    
    # Создание таблицы пользователей
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT DEFAULT 'client',
            FOREIGN KEY (client_id) REFERENCES клиенты(id)
        )
    ''')
    
    # Создание админа
    cursor.execute("SELECT * FROM users WHERE username = 'admin'")
    if not cursor.fetchone():
        cursor.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)",
                       ('admin', hash_password('admin123'), 'admin'))
    
    conn.commit()
    conn.close()
    print("✅ База данных успешно создана и заполнена тестовыми данными!")

# Функция для автоматического назначения курьера
def auto_assign_courier(order_id):
    """Автоматически назначает свободного курьера для заказа"""
    conn = get_db()
    cursor = conn.cursor()
    
    # Ищем свободных курьеров (статус 'active' и занятость < 3)
    free_couriers = cursor.execute('''
        SELECT id, занятость FROM курьеры 
        WHERE статус = 'active' AND занятость < 3
        ORDER BY занятость ASC, рейтинг DESC
    ''').fetchall()
    
    if free_couriers:
        # Выбираем случайного из свободных
        courier = random.choice(free_couriers)
        courier_id = courier['id']
        
        # Назначаем курьера
        cursor.execute('''
            UPDATE заказы SET курьер_id = ?, статус = 'in_progress' 
            WHERE id = ?
        ''', (courier_id, order_id))
        
        # Увеличиваем занятость курьера
        cursor.execute('''
            UPDATE курьеры SET занятость = занятость + 1 
            WHERE id = ?
        ''', (courier_id,))
        
        conn.commit()
        print(f"✅ Курьер {courier_id} назначен на заказ {order_id}")
        return courier_id
    else:
        print(f"⚠️ Нет свободных курьеров для заказа {order_id}")
    
    conn.close()
    return None

# Функция для автоматического обновления статуса доставки
def update_delivery_status():
    """Фоновая задача: обновляет статусы доставки каждые 10 секунд"""
    while True:
        time.sleep(10)  # Проверяем каждые 10 секунд
        try:
            conn = get_db()
            cursor = conn.cursor()
            
            # Получаем заказы в процессе доставки
            orders_in_progress = cursor.execute('''
                SELECT id, дата_заказа FROM заказы 
                WHERE статус = 'in_progress' AND дата_доставки IS NULL
            ''').fetchall()
            
            for order in orders_in_progress:
                order_time = datetime.strptime(order['дата_заказа'], '%Y-%m-%d %H:%M:%S')
                time_diff = (datetime.now() - order_time).total_seconds() / 60  # в минутах
                
                # Рандомное время доставки от 15 до 45 минут
                if time_diff > random.randint(15, 45):
                    # Доставляем заказ
                    cursor.execute('''
                        UPDATE заказы SET статус = 'delivered', 
                        дата_доставки = ? WHERE id = ?
                    ''', (datetime.now().strftime('%Y-%m-%d %H:%M:%S'), order['id']))
                    
                    # Освобождаем курьера
                    cursor.execute('''
                        UPDATE курьеры SET занятость = занятость - 1 
                        WHERE id = (SELECT курьер_id FROM заказы WHERE id = ?)
                    ''', (order['id'],))
                    
                    print(f"📦 Заказ {order['id']} доставлен!")
            
            conn.commit()
            conn.close()
        except Exception as e:
            print(f"Ошибка при обновлении статусов: {e}")

# Запускаем фоновый поток для обновления статусов
def start_background_tasks():
    thread = threading.Thread(target=update_delivery_status, daemon=True)
    thread.start()

# Инициализация базы данных и фоновых задач
init_database()
start_background_tasks()

# ------------------ КОРЗИНА ------------------
def get_cart():
    return session.get('cart', {})

def save_cart(cart):
    session['cart'] = cart

def add_to_cart(product_id, product_name, price, quantity=1):
    cart = get_cart()
    prod_id = str(product_id)
    if prod_id in cart:
        cart[prod_id]['quantity'] += quantity
    else:
        cart[prod_id] = {'name': product_name, 'price': float(price), 'quantity': quantity}
    save_cart(cart)

def clear_cart():
    session['cart'] = {}

# ------------------ МАРШРУТЫ ------------------
@app.route('/')
def index():
    conn = get_db()
    products = conn.execute("SELECT * FROM товары WHERE наличие > 0").fetchall()
    conn.close()
    cart = get_cart()
    cart_count = sum(item['quantity'] for item in cart.values())
    return render_template('index.html', products=products, cart_count=cart_count)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        name = request.form['name']
        surname = request.form['surname']
        phone = request.form['phone']
        email = request.form['email']
        address = request.form['address']
        username = request.form['username']
        password = request.form['password']
        
        conn = get_db()
        cursor = conn.cursor()
        try:
            cursor.execute('''
                INSERT INTO клиенты (имя, фамилия, телефон, email, адрес, бонусы, категория)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (name, surname, phone, email, address, 0, 'обычный'))
            client_id = cursor.lastrowid
            
            cursor.execute('''
                INSERT INTO users (client_id, username, password, role)
                VALUES (?, ?, ?, ?)
            ''', (client_id, username, hash_password(password), 'client'))
            
            conn.commit()
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            return "Пользователь с таким именем уже существует"
        finally:
            conn.close()
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        conn = get_db()
        user = conn.execute('''
            SELECT * FROM users WHERE username = ? AND password = ?
        ''', (username, hash_password(password))).fetchone()
        conn.close()
        
        if user:
            session['user_id'] = user['id']
            session['username'] = user['username']
            session['role'] = user['role']
            session['client_id'] = user['client_id']
            if user['role'] == 'admin':
                return redirect(url_for('admin_panel'))
            return redirect(url_for('profile'))
        return "Неверное имя пользователя или пароль"
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

@app.route('/profile')
def profile():
    if 'user_id' not in session or session.get('role') != 'client':
        return redirect(url_for('login'))
    
    conn = get_db()
    client = conn.execute('SELECT * FROM клиенты WHERE id = ?', (session['client_id'],)).fetchone()
    conn.close()
    return render_template('profile.html', client=client)

@app.route('/add_to_cart/<int:product_id>', methods=['POST'])
def add_to_cart_route(product_id):
    conn = get_db()
    product = conn.execute('SELECT * FROM товары WHERE id = ?', (product_id,)).fetchone()
    conn.close()
    if product:
        quantity = int(request.form.get('quantity', 1))
        add_to_cart(product_id, product['название'], product['цена'], quantity)
    return redirect(url_for('index'))

@app.route('/cart')
def view_cart():
    cart = get_cart()
    total = sum(item['price'] * item['quantity'] for item in cart.values())
    return render_template('cart.html', cart=cart, total=total)

@app.route('/remove_from_cart/<int:product_id>')
def remove_from_cart(product_id):
    cart = get_cart()
    if str(product_id) in cart:
        del cart[str(product_id)]
        save_cart(cart)
    return redirect(url_for('view_cart'))

@app.route('/update_cart/<int:product_id>', methods=['POST'])
def update_cart(product_id):
    quantity = int(request.form.get('quantity', 0))
    cart = get_cart()
    if str(product_id) in cart:
        if quantity <= 0:
            del cart[str(product_id)]
        else:
            cart[str(product_id)]['quantity'] = quantity
        save_cart(cart)
    return redirect(url_for('view_cart'))

@app.route('/checkout', methods=['POST'])
def checkout():
    if 'user_id' not in session or session.get('role') != 'client':
        return redirect(url_for('login'))
    
    cart = get_cart()
    if not cart:
        return redirect(url_for('index'))
    
    total = sum(item['price'] * item['quantity'] for item in cart.values())
    payment_method = request.form.get('payment_method', 'cash')
    
    conn = get_db()
    cursor = conn.cursor()
    
    # Создаём заказ со статусом 'pending'
    cursor.execute('''
        INSERT INTO заказы (клиент_id, статус, сумма, способ_оплаты, примечания)
        VALUES (?, ?, ?, ?, ?)
    ''', (session['client_id'], 'pending', total, payment_method, 'Через сайт'))
    order_id = cursor.lastrowid
    
    # Добавляем товары в заказ
    for prod_id, item in cart.items():
        cursor.execute('''
            INSERT INTO состав_заказа (заказ_id, товар_id, количество, цена_в_момент_заказа)
            VALUES (?, ?, ?, ?)
        ''', (order_id, int(prod_id), item['quantity'], item['price']))
    
    conn.commit()
    
    # АВТОМАТИЧЕСКИ НАЗНАЧАЕМ КУРЬЕРА
    auto_assign_courier(order_id)
    
    conn.close()
    
    clear_cart()
    return redirect(url_for('my_orders'))

@app.route('/my_orders')
def my_orders():
    if 'user_id' not in session or session.get('role') != 'client':
        return redirect(url_for('login'))
    
    conn = get_db()
    orders = conn.execute('''
        SELECT з.*, к.имя as курьер_имя, к.фамилия as курьер_фамилия
        FROM заказы з
        LEFT JOIN курьеры к ON з.курьер_id = к.id
        WHERE з.клиент_id = ? 
        ORDER BY з.дата_заказа DESC
    ''', (session['client_id'],)).fetchall()
    conn.close()
    return render_template('orders.html', orders=orders)

@app.route('/track_order/<int:order_id>')
def track_order(order_id):
    """Отслеживание статуса заказа в реальном времени"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db()
    order = conn.execute('''
        SELECT з.*, к.имя as курьер_имя, к.фамилия as курьер_фамилия, 
               к.транспорт, к.рейтинг, к.телефон as курьер_телефон
        FROM заказы з
        LEFT JOIN курьеры к ON з.курьер_id = к.id
        WHERE з.id = ?
    ''', (order_id,)).fetchone()
    conn.close()
    
    if not order or (session.get('role') != 'admin' and order['клиент_id'] != session.get('client_id')):
        return "Доступ запрещён", 403
    
    return render_template('track_order.html', order=order)

# ------------------ АДМИН ПАНЕЛЬ ------------------
@app.route('/admin')
def admin_panel():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('login'))
    
    conn = get_db()
    total_orders = conn.execute("SELECT COUNT(*) as count FROM заказы").fetchone()['count']
    total_clients = conn.execute("SELECT COUNT(*) as count FROM клиенты").fetchone()['count']
    total_couriers = conn.execute("SELECT COUNT(*) as count FROM курьеры").fetchone()['count']
    total_revenue = conn.execute("SELECT SUM(сумма) as sum FROM заказы WHERE статус = 'delivered'").fetchone()['sum'] or 0
    
    orders = conn.execute('''
        SELECT з.*, к.имя as клиент_имя, к.фамилия as клиент_фамилия,
               кур.имя as курьер_имя, кур.фамилия as курьер_фамилия,
               кур.телефон as курьер_телефон
        FROM заказы з
        LEFT JOIN клиенты к ON з.клиент_id = к.id
        LEFT JOIN курьеры кур ON з.курьер_id = кур.id
        ORDER BY з.дата_заказа DESC
    ''').fetchall()
    
    clients = conn.execute("SELECT * FROM клиенты").fetchall()
    couriers = conn.execute("SELECT * FROM курьеры ORDER BY занятость ASC, рейтинг DESC").fetchall()
    products = conn.execute("SELECT * FROM товары").fetchall()
    
    conn.close()
    
    return render_template('admin.html', 
                         total_orders=total_orders,
                         total_clients=total_clients,
                         total_couriers=total_couriers,
                         total_revenue=total_revenue,
                         orders=orders,
                         clients=clients,
                         couriers=couriers,
                         products=products)

@app.route('/admin/force_assign_courier/<int:order_id>')
def force_assign_courier(order_id):
    """Принудительное назначение курьера админом"""
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('login'))
    
    auto_assign_courier(order_id)
    return redirect(url_for('admin_panel'))

@app.route('/admin/update_order_status', methods=['POST'])
def update_order_status():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('login'))
    
    order_id = request.form.get('order_id')
    status = request.form.get('status')
    
    conn = get_db()
    
    if status == 'delivered' and not request.form.get('courier_id'):
        # Если доставлен, освобождаем курьера
        cursor = conn.cursor()
        cursor.execute('SELECT курьер_id FROM заказы WHERE id = ?', (order_id,))
        order = cursor.fetchone()
        if order and order['курьер_id']:
            cursor.execute('UPDATE курьеры SET занятость = занятость - 1 WHERE id = ?', (order['курьер_id'],))
        cursor.execute('UPDATE заказы SET статус = ?, дата_доста
