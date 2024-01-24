from flask import Flask, flash, render_template, request, redirect, url_for, session
import pymysql
import re
from config import *

app = Flask(__name__)

app.secret_key = 'secretKey'

try:
    mysql = pymysql.connect(host=MYSQL_HOST,
                          user=MYSQL_USER,
                          password=MYSQL_PASSWORD,
                          db=MYSQL_DB,
                          port=MYSQL_PORT,
                          charset='utf8mb4',
                          cursorclass=pymysql.cursors.DictCursor)
except pymysql.err.OperationalError as e:
    print('Error: %d : %s' % (e.args[0], e.args[1]))


@app.route('/')
@app.route('/login', methods=['GET', 'POST'])
def login():
    msg = ''
    if request.method == 'POST' and 'email' in request.form and 'password' in request.form:
        email = request.form['email']
        password = request.form['password']
        cursor = mysql.cursor()
        args = (email, password)
        cursor.callproc('loginUser', args)
        account = cursor.fetchall()
        mysql.commit()
        if len(account) > 0:
            session['loggedin'] = True
            session['email'] = account[0]['email']
            cursor.callproc('isCustomer', [email])
            customer = cursor.fetchall()

            cursor.callproc('isSeller', [email])
            seller = cursor.fetchall()
            
            cursor.callproc('isShipper', [email])
            shipper = cursor.fetchall()
                
            if (len(customer) > 0):
                session['userType'] = 'customer'
                return redirect(url_for('userHome'))
            elif (len(seller) > 0):
                session['userType'] = 'seller'
                return redirect(url_for('sellerHome'))
            elif (len(shipper) > 0):
                session['userType'] = 'shipper'
                return redirect(url_for('shipperHome'))
        else:
            msg = 'Incorrect email / password !'
        cursor.close()
    return render_template('login.html', msg=msg)


@app.route('/')
@app.route('/userHome', methods=['GET', 'POST'])
def userHome():
    cursor = mysql.cursor()
    cursor.callproc('categoryFilter', [''])
    products = cursor.fetchall()
    mysql.commit()
    return render_template('userHome.html', products=products)


@app.route('/account')
def account():
    cursor = mysql.cursor()
    cursor.callproc('getUser', [session['email']])
    mysql.commit()
    account = cursor.fetchall()
    cursor.callproc('getCard', [session['email']])
    mysql.commit()
    cards = cursor.fetchall()
    return render_template('myAccount.html', user=account, cards=cards)


@app.route('/deleteCard/<card_no>', methods=['GET', 'POST'])
def deleteCard(card_no):
    cursor = mysql.cursor()
    cursor.callproc('deleteCard', [card_no])
    mysql.commit()
    return redirect(url_for('account'))


@app.route('/addCard', methods=['GET', 'POST'])
def addCard():
    cursor = mysql.cursor()
    if (request.method == "POST"):
        try:
            cursor.callproc('addCard', [request.form['cardNo'], int(
                request.form['cvv']), request.form['expiryDate'], session['email']])
            mysql.commit()
        except pymysql.err.OperationalError as e:
            print(e)
    return redirect(url_for('account'))


@app.route('/updateUser', methods=['GET', 'POST'])
def updateUser():
    cursor = mysql.cursor()
    if request.method == 'POST':
        try:
            cursor.callproc('updateUser', [request.form['firstName'], request.form['lastName'], session['email'],
                                           request.form['password'], request.form[
                'phone'],  request.form['street'],  request.form['city'],
                request.form['state'][0:2], request.form['zip']])
            mysql.commit()
        except pymysql.err.OperationalError as e:
            print(e)
    return redirect(url_for('account'))


@app.route('/userorders')
def userOrders():
    cursor = mysql.cursor()
    cursor.callproc('getOrdersForUser', [session['email']])
    mysql.commit()
    orders =cursor.fetchall()
    orderItems = {}
    for order in orders:
        orderId = order['orderID']
        if orderId not in orderItems.keys():
            orderDetails = {}
            try:
                cursor.callproc('getProduct', [order['productID']])
                mysql.commit()
            except pymysql.err.OperationalError as e:
                print(e)
            product = cursor.fetchall()
            orderDetails['quantity'] = order['quantity']
            orderDetails['paymentID'] = order['paymentID']
            orderDetails['status'] = [
                {'statusType': order['status'], 'time': str(order['timestamp'])[0:10]}]
            orderDetails['total'] = order['total']
            orderDetails['productName'] = product[0]['name']
            orderDetails['productURL'] = product[0]['imageURL']
            orderDetails['orderID'] = order['orderID']
            orderItems[order['orderID']] = orderDetails
        else:
            orderItems[order['orderID']]['status'].append(
                {'statusType': order['status'], 'time': str(order['timestamp'])[0:10]})
    return render_template('myOrders.html', orders=orderItems.values())


@app.route('/product/<product_id>')
def product(product_id):
    cursor = mysql.cursor()
    try:
        cursor.callproc('getProduct', [product_id])
        mysql.commit()
    except pymysql.err.OperationalError as e:
        print(e)
    product = cursor.fetchall()
    cursor.callproc('getReviews', [product_id])
    mysql.commit()
    reviews = cursor.fetchall()
    cursor.execute('SELECT checkUserPurchasedProduct(%s, %s)',
                   (product_id, session['email']))
    res = cursor.fetchall()
    return render_template('product.html', product=product, reviews=reviews, didBuy=True if list(res[0].values())[0] == 1 else False)


@app.route('/postReview/<product_id>', methods=['GET', 'POST'])
def postReview(product_id):
    cursor = mysql.cursor()
    if request.method == 'POST':
        reviewText = request.form['reviewText']
        cursor.callproc('insertReview', [
                        reviewText, session['email'], product_id])
        mysql.commit()
    return redirect(url_for('product', product_id=product_id))


@app.route('/buyProduct/<product_id>', methods=['GET', 'POST'])
def buyProduct(product_id):
    quantity = 1
    if request.method == 'POST':
        quantity = request.form['quantity']
    cursor = mysql.cursor()
    try:
        cursor.callproc('getProduct', [product_id])
        mysql.commit()
    except pymysql.err.OperationalError as e:
        print(e)
    product = cursor.fetchall()
    cursor.callproc('getCard', [session['email']])
    mysql.commit()
    cards = cursor.fetchall()

    cursor.callproc('getPromos')
    mysql.commit()
    promos = cursor.fetchall()
    return render_template('order.html', product=product, quantity=int(quantity) if quantity else 1, cards=cards, promos=promos)


@app.route('/orderProduct/<product_id>/<quantity>', methods=['GET', 'POST'])
def orderProduct(product_id, quantity):
    cardNo = ""
    promoID = ""
    if request.method == 'POST':
        if 'card' not in request.form.keys():
            flash('Please Choose a Card')
            return redirect(url_for('buyProduct', product_id=product_id))
        cardNo = request.form['card']
        if 'promo' in request.form.keys():
            promoID = request.form['promo']
    try:
        cursor = mysql.cursor()
        cursor.callproc('buyProduct', [session['email'], int(
            product_id), int(quantity), cardNo])
        mysql.commit()
    except pymysql.err.OperationalError as e:
        print(e)
    return redirect(url_for('userOrders'))


@app.route('/logout')
def logout():
    session.pop('loggedin', None)
    session.pop('email', None)
    session.pop('userType', None)
    return redirect(url_for('login'))


@app.route('/deleteUser')
def deleteUser():
    cursor = mysql.cursor()
    cursor.callproc('deleteUser', [session['email']])
    return redirect(url_for('logout'))


@app.route('/register', methods=['GET', 'POST'])
def register():
    msg = ''
    if request.method == 'POST':
        cursor = mysql.cursor()
        email = request.form['email']
        sql = "SELECT * from users where email=(%s)"
        cursor.execute(sql, (email,))
        account = cursor.fetchall()
        if account:
            msg = 'Account already exists !'
        elif (request.form['user_type'] == 'customer'):
            try:
                cursor.callproc('registerCustomer', [request.form['firstName'], request.form['lastName'], request.form['email'],
                                                     request.form['password'], request.form[
                                                         'phone'],  request.form['street'],  request.form['city'],
                                                     request.form['state'][0:2], request.form['zip']])
                mysql.commit()
            except pymysql.err.OperationalError as e:
                print(e)
            session['loggedin'] = True
            session['email'] = email
            session['userType'] = 'customer'
            return redirect(url_for('userHome'))
        elif (request.form['user_type'] == 'seller'):
            try:
                cursor.callproc('registerSeller', [request.form['firstName'], request.form['lastName'], request.form['email'],
                                                   request.form['password'], request.form[
                    'phone'],  request.form['street'],  request.form['city'],
                    request.form['state'][0:2], request.form['zip'], int(request.form['taxId'])])
                mysql.commit()
            except pymysql.err.OperationalError as e:
                print(e)
            session['loggedin'] = True
            session['email'] = email
            session['userType'] = 'seller'
            return redirect(url_for('sellerHome'))
        elif (request.form['user_type'] == 'shipper'):
            try:
                cursor.callproc('registerShipper', [request.form['firstName'], request.form['lastName'], request.form['email'],
                                                    request.form['password'], request.form[
                    'phone'],  request.form['street'],  request.form['city'],
                    request.form['state'][0:2], request.form['zip'], request.form['companyName']])
                mysql.commit()
            except pymysql.err.OperationalError as e:
                print(e)
            session['loggedin'] = True
            session['email'] = email
            session['userType'] = 'shipper'
            return redirect(url_for('shipperHome'))
    return render_template('register.html', msg=msg)


@app.route('/sellerHome', methods=['GET', 'POST'])
def sellerHome():
    products = []
    cursor = mysql.cursor()
    cursor.callproc('getSellerProducts', [session['email']])
    mysql.commit()
    products = cursor.fetchall()

    cursor.callproc('totalRevenue', [session['email']])
    mysql.commit()
    revenue = cursor.fetchall()
    
    cursor.callproc('totalProfit', [session['email']])
    mysql.commit()
    profit = cursor.fetchall()

    cursor.execute('SELECT maximumProductSold(%s)', (session['email'],))
    topProduct = cursor.fetchall()
    xValues = ""
    yValues = ""
    cursor.callproc('monthlyRevenue', [session['email']])
    mysql.commit()
    monthlyRevenue = cursor.fetchall()
    
    cursor.callproc('CalculateTotalMsrpByCategoryForSeller', [session['email']])
    mysql.commit()
    ctmbcfs = cursor.fetchall()
    cat_names = []
    tot_MSRP = []
    for result in ctmbcfs:
        cat_names.append(result['name'])
        tot_MSRP.append(result['totalMsrp'])
    
    print(cat_names)
    print(tot_MSRP)

    for i in monthlyRevenue:
        xValues += str(i['months'])+"|"
        yValues += str(i['sum(total)'])+"|"
        
    print(xValues)
    print(yValues)

    print(revenue)
    print(profit)
    print(topProduct)
    print(products)
    print(list(topProduct[0].values())[0])
    if len(topProduct)> 0:
        topProduct = list(topProduct[0].values())[0]
    return render_template('sellerHome.html', products=products, revenue=list(revenue[0].values())[0], profit=list(profit[0].values())[0], topProduct=topProduct, xValues=xValues, yValues=yValues,xValues2=cat_names,yValues2=tot_MSRP)


@app.route('/delistProduct/<product_id>', methods=['GET', 'POST'])
def delistProduct(product_id):
    try:
        cursor = mysql.cursor()
        cursor.callproc('toggleProductStatus', [product_id])
        mysql.commit()
    except pymysql.err.OperationalError as e:
        print(e)
    return redirect(url_for('sellerHome'))


@app.route('/addProduct', methods=['GET', 'POST'])
def addProduct():
    cursor = mysql.cursor()
    sql = "SELECT * from category"
    cursor.execute(sql)
    res = cursor.fetchall()
    if request.method == "POST":
        cursor.callproc('insertProduct', [request.form['productName'], request.form['imageURL'],
                        float(request.form['unitPrice']), float(
                            request.form['msrPrice']), int(request.form['quantity']),
                        request.form['category'], session['email']])
        mysql.commit()
        flash('Product Added!')
    return render_template('addProduct.html', categories=res)


@app.route('/shipperHome', methods=['GET', 'POST'])
def shipperHome():
    cursor = mysql.cursor()
    cursor.callproc('getShipper', [session['email']])
    mysql.commit()
    shipper = cursor.fetchall()
    
    cursor.callproc('getUnpickedOrders', [])
    mysql.commit()
    unpickedOrders = cursor.fetchall()
    
    cursor.callproc('getPickedOrders', [session['email']])
    mysql.commit()
    pOrders = cursor.fetchall()
    
    pickedOrders = {}
    blacklist = set()
    for order in pOrders:
        orderId = order['orderID']
        orderStatus = order['status']
        if orderStatus == 'DELIVERED':
            blacklist.add(orderId)
        if orderId not in pickedOrders.keys() and orderId not in blacklist:
            orderDetails = {}
            orderDetails['orderID'] = orderId
            orderDetails['lastUpdate'] = str(order['timestamp'])[0:10]
            orderDetails['orderStatus'] = order['status']
            pickedOrders[orderId] = orderDetails
    return render_template('shipperHome.html', shipper=shipper, unpickedOrders=unpickedOrders, pickedOrders=pickedOrders.values())


@app.route('/updateShipperID/<orderID>', methods=['GET', 'POST'])
def updateShipperID(orderID):
    cursor = mysql.cursor()
    cursor.callproc('updateShipperID', [orderID, session['email']])
    mysql.commit()
    return redirect(url_for('shipperHome'))


@app.route('/updateStatus/<orderID>', methods=['GET', 'POST'])
def updateStatus(orderID):
    cursor = mysql.cursor()
    if request.method == 'POST':
        cursor.callproc('updateOrderStatus', [
                        orderID, request.form['orderStatus']])
        mysql.commit()
    return redirect(url_for('shipperHome'))


@app.route('/deleteReview/<reviewID>', methods=['GET', 'POST'])
def deleteReview(reviewID):
    cursor = mysql.cursor()
    cursor.callproc('deleteReview', [reviewID])
    mysql.commit()
    return redirect(url_for('userHome'))


if __name__ == '__main__':
    app.run(port=5080)
