DROP DATABASE if EXISTS zelando;
CREATE DATABASE if not EXISTS zelando;

USE zelando;

DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(100) PRIMARY KEY,
    password VARCHAR(20) NOT NULL,
    phoneNo CHAR(10) NOT NULL,
    street VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state CHAR(2) NOT NULL,
    zipcode CHAR(5) NOT NULL
);

DROP TABLE IF EXISTS customer;
CREATE TABLE IF NOT EXISTS customer (
    customerID INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (email)
        REFERENCES users (email)
        ON UPDATE RESTRICT ON DELETE CASCADE
);


DROP TABLE IF EXISTS seller;
CREATE TABLE IF NOT EXISTS seller (
    sellerID INT AUTO_INCREMENT PRIMARY KEY,
    taxID INT UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (email)
        REFERENCES users (email)
        ON UPDATE RESTRICT ON DELETE CASCADE
);


DROP TABLE IF EXISTS shipper;
CREATE TABLE IF NOT EXISTS shipper (
    shipperID INT AUTO_INCREMENT PRIMARY KEY,
    companyName VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (email)
        REFERENCES users (email)
        ON UPDATE RESTRICT ON DELETE CASCADE
);

DROP TABLE IF EXISTS category;
CREATE TABLE IF NOT EXISTS category (
    categoryID INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL
);


DROP TABLE IF EXISTS product;
CREATE TABLE IF NOT EXISTS product (
    productID INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(400) NOT NULL,
    imageURL VARCHAR(1000),
    unitPrice DOUBLE NOT NULL,
    msrp DOUBLE NOT NULL,
    units INT NOT NULL DEFAULT 1,
    status ENUM('ACTIVE', 'INACTIVE'),
    categoryID INT NOT NULL,
    sellerID INT NOT NULL,
    FOREIGN KEY (categoryID)
        REFERENCES category (categoryID)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (sellerID)
        REFERENCES seller (sellerID)
        ON UPDATE RESTRICT ON DELETE CASCADE
);


DROP TABLE IF EXISTS review;
CREATE TABLE IF NOT EXISTS review (
    reviewID INT AUTO_INCREMENT PRIMARY KEY,
    text VARCHAR(1500) NOT NULL DEFAULT '',
    date DATE NOT NULL,
    customerID INT NOT NULL,
    productID INT NOT NULL,
    FOREIGN KEY (customerID)
        REFERENCES customer (customerID)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (productID)
        REFERENCES product (productID)
        ON UPDATE RESTRICT ON DELETE CASCADE
);

DROP TABLE IF EXISTS orders;
CREATE TABLE IF NOT EXISTS orders (
    orderID INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATE NOT NULL,
    customerID INT NOT NULL,
    productID INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    shipperID INT,
    FOREIGN KEY (customerID)
        REFERENCES customer (customerID)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (productID)
        REFERENCES product (productID)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (shipperID)
        REFERENCES shipper (shipperID)
        ON UPDATE RESTRICT ON DELETE CASCADE
);

DROP TABLE IF EXISTS card;
CREATE TABLE IF NOT EXISTS card (
    cardNo CHAR(16) PRIMARY KEY,
    cvv INT NOT NULL,
    expiryDate DATE NOT NULL,
    customerID INT NOT NULL,
    FOREIGN KEY (customerID)
        REFERENCES customer (customerID)
        ON UPDATE RESTRICT ON DELETE CASCADE
);

DROP TABLE IF EXISTS orderTracking;
CREATE TABLE IF NOT EXISTS orderTracking (
    orderID INT NOT NULL,
    status ENUM('ORDERED', 'IN-TRANSIT', 'DELIVERED') DEFAULT 'ORDERED',
    timestamp DATE,
    PRIMARY KEY (orderID , status),
    FOREIGN KEY (orderID)
        REFERENCES orders (orderID)
        ON UPDATE RESTRICT ON DELETE CASCADE
);

DROP TABLE IF EXISTS payment;
CREATE TABLE IF NOT EXISTS payment (
    paymentID INT AUTO_INCREMENT PRIMARY KEY,
    cardNo CHAR(16),
    orderID INT NOT NULL,
    total DOUBLE DEFAULT 0.0,
    timestamp DATE,
    FOREIGN KEY (orderID)
        REFERENCES orders (orderID)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (cardNo)
        REFERENCES card (cardNo)
        ON UPDATE RESTRICT ON DELETE SET NULL
);



delimiter $$
create procedure loginUser(email_p varchar(64), passowrd_p varchar(64))
	begin
		select * from users where email = email_p and password = passowrd_p;
    end $$
delimiter ;


delimiter $$
create procedure isCustomer(email_p varchar(64))
	begin
		select * from customer where email = email_p;
    end $$
delimiter ; 


delimiter $$
create procedure isSeller(email_p varchar(64))
	begin
		select * from seller where email = email_p;
    end $$
delimiter ; 


delimiter $$
create procedure isShipper(email_p varchar(64))
	begin
		select * from shipper where email = email_p;
    end $$
delimiter ;


drop procedure if exists registerCustomer;
 delimiter $$
create procedure registerCustomer(firstname_p varchar(100), lastname_p varchar(100), email_p varchar(100),password_p varchar(100), phoneno_p char(10), street_p varchar(100), city_p varchar(100), state_p char(2), zipcode_p char(5))
	begin
		if email_p in (select email from users) then
            select * from users where email = email_p;
		else
			insert into users values(firstname_p,lastname_p,email_p,password_p,phoneno_p,street_p,city_p,state_p,zipcode_p);
            insert into customer(email) values(email_p);
	   end if;
    end $$
delimiter ;  


drop procedure if exists registerSeller;
 delimiter $$
create procedure registerSeller(firstname_p varchar(100), lastname_p varchar(100), email_p varchar(100),password_p varchar(100), phoneno_p char(10), street_p varchar(100), city_p varchar(100), state_p char(2), zipcode_p char(5),taxID_p int)
	begin
		if email_p in (select email from users) then
            select * from users where email = email_p;
		else
			insert into users values(firstname_p,lastname_p,email_p,password_p,phoneno_p,street_p,city_p,state_p,zipcode_p);
            insert into seller(taxID,email) values(taxID_p,email_p);
	   end if;
    end $$
delimiter ;      


drop procedure if exists registerShipper;
delimiter $$
create procedure registerShipper(firstname_p varchar(100), lastname_p varchar(100), email_p varchar(100),password_p varchar(100), phoneno_p char(10), street_p varchar(100), city_p varchar(100), state_p char(2), zipcode_p int,companyName_p varchar(100))
	begin
		if email_p in (select email from users) then
            select * from users where email = email_p;
		else
			insert into users values(firstname_p,lastname_p,email_p,password_p,phoneno_p,street_p,city_p,state_p,zipcode_p);
            insert into shipper(companyName,email) values(companyName_p,email_p);
	   end if;
    end $$
delimiter ;  


drop procedure if exists insertProduct;
delimiter $$
create procedure insertProduct(name_p varchar(400),imageURL_p varchar(1000), unitPrice_p double, msrp_p double, units_p int, categoryId_p int, email_p varchar(100))
	begin
    declare sellerID_p int;
    set sellerID_p = (select sellerID from seller where email = email_p limit 1);
    insert into product(name,imageURL,unitPrice,msrp,units,status,categoryID,sellerID) values(name_p,imageURL_p,unitPrice_p,msrp_p,units_p,'ACTIVE',categoryId_p,sellerID_p);
	end$$
    
delimiter ;


drop procedure if exists getUser;
delimiter $$
create procedure getUser(email_p varchar(100))
	begin
		select * from users where email = email_p;
    end $$
delimiter ;


drop procedure if exists  categoryFilter ;
delimiter $$
create procedure categoryFilter(IN categories_p varchar(255))
	begin
		set @sql1 = 'select * from product where status = 1 and units > 0 ';
		set @sql2 = concat(' and  categoryID in (',categories_p,')');
		set @statement = concat(@sql1,@sql2);
		if LENGTH(categories_p) = 0 then
			prepare stmt from @sql1;
            execute stmt;
            deallocate prepare stmt;
        else    			
			prepare stmt from @statement;
			execute stmt;
			deallocate prepare stmt;
		end if;
		-- select * from product where categoryID in (categories);
    end $$
delimiter ;




drop procedure if exists updateUser;
 delimiter $$
create procedure updateUser(firstname_p varchar(100), lastname_p varchar(100), email_p varchar(100),password_p varchar(100), phoneno_p char(10), street_p varchar(100), city_p varchar(100), state_p char(2), zipcode_p char(5))
	begin
		if email_p in (select email from users) then
            update users set 
            firstname = firstname_p,
            lastname = lastname_p,
            email = email_p, 
            password = password_p,
            phoneno = phoneno_p, 
            street = street_p,
			city = city_p,
            state = state_p,
            zipcode = zipcode_p
            where email = email_p;            				
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email ID does not exist';
	   end if;
    end $$
delimiter ;   



drop procedure if exists getProduct;
 delimiter $$
create procedure getProduct(productID_p int)
	begin
		if productID_p in (select productID from product) then
            select * from product where productID = productID_p;            				
		else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product ID does not exist';
	   end if;
    end $$
delimiter ;


drop procedure if exists getReviews;
delimiter $$
create procedure getReviews(productID_p int)
	begin
		if productID_p in (select productID from product) then
				select review.*, concat(firstName,' ',lastName) from ((review join customer on review.customerID = customer.customerID) 
					join users using(email) )
					where review.productID = productID_p;
		end if;
	end $$
delimiter ;


drop procedure if exists insertReview;
delimiter $$
create procedure insertReview(text_p varchar(1500),email_p varchar(100),productID_p int)
	begin
    declare customerID_p int;
    set customerID_p = (select customerID from customer where email = email_p limit 1);
    insert into review(text,date,customerID,productID) values(text_p,current_date(),customerID_p,productID_p);
	end$$
    
delimiter ;   


drop function if exists checkUserPurchasedProduct;
delimiter $$
create function checkUserPurchasedProduct(productID_p varchar(64),email_p varchar(64))
		returns int
        deterministic reads sql data
	begin
		declare result int;
        declare customerID_var int;
        
		set customerID_var = (select customerID from customer where email = email_p limit 1); 

        if  customerID_var in (select customerID from orders ) and productID_p in (select productID from orders ) then
			set result = 1;
		else
			set result = 0;
		end if;	
      return result;
    end $$
delimiter ;


drop procedure if exists deleteUser;
delimiter $$
create procedure deleteUser(email_p varchar(100))
	begin
		delete from users where email = email_p;
	end $$
delimiter ;


drop procedure if exists getCard;
delimiter $$
create procedure getCard(email_p varchar(100))
	begin
		declare customerID_var int;
        set customerID_var = (select customerID from customer where email_p = email limit 1);
		select * from card where customerID_var = customerID;         
	end $$
delimiter ;


drop procedure if exists deleteCard;
delimiter $$
create procedure deleteCard(cardNo_p char(16))
	begin
		delete from card
        where cardNo = cardNo_p;
	end $$
delimiter ;


drop procedure if exists addCard;
delimiter $$
create procedure addCard(cardNo_p char(16),cvv_p int, expiryDate date, email_p varchar(100))
	begin
    declare customerID_var int;
	set customerID_var = (select customerID from customer where email_p = email limit 1);
		if  cvv_p <=999 then
			insert into card values(cardNo_p,cvv_p,expiryDate,customerID_var);
        else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The CVV is greater than 3 digits';
        end if;
	end $$
delimiter ;


drop procedure if exists buyProduct;
delimiter $$
create procedure buyProduct(email_p varchar(100),productID_p int,quantity_p int, cardNo_p char(16))
	begin
		declare unit_var int;
        declare customerID_p int;
        declare orderID_var int;
        declare total_p double;
        set customerID_p = (select customerID from customer where email = email_p limit 1);
		set unit_var  = (select units from product where productID = productID_p);
        set total_p = (select msrp from product where productID = productID_p) * quantity_p;
        
        if unit_var >= quantity_p then 
        -- reduce product quantity
        update product set units = unit_var-quantity_p where productID = productID_p;
        -- add to orders
        insert into orders(timestamp,customerID,productID,quantity,shipperID) values (current_date(),customerID_p,productID_p,quantity_p,null);
         -- order tracking
         set orderID_var = (SELECT LAST_INSERT_ID());
         insert into orderTracking(orderID,status,timestamp) values (orderID_var,'ORDERED',current_date());
         -- payment
         insert into payment(cardNo,orderID,total,timestamp) values(cardNo_p,orderID_var,total_p,current_date());
         else 
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The inserted quantity is greater than the available stock';
		end if;
         
	end $$

delimiter ;


drop procedure if exists getOrdersForUser;
delimiter $$
create procedure getOrdersForUser(email_p varchar(64))
	begin
		declare result int;
        declare customerID_var int;
         
        select * from orders join orderTracking using(orderID)
			join payment using(orderID) 
        where customerID = (select customerID from customer where email = email_p limit 1)
        order by orderID;
        
	end $$
delimiter ;


drop procedure if exists getSellerProducts;
delimiter $$
create procedure getSellerProducts(email_p varchar(64))
	begin
        select * from product where status = 1 and sellerID = (select sellerID from seller where email = email_p limit 1);
    end $$
delimiter ;

drop procedure if exists toggleProductStatus;
delimiter $$
create procedure toggleProductStatus(productID_p int)
	begin
		declare status_var enum('ACTIVE','INACTIVE');
        if productID_p in (select productID from product) then 
			select status into status_var from product where productID = productID_p;
			if status_var =1 then 
				set status_var = 2;
			else 
				set status_var = 1;
			end if;
			
			update product set status = status_var where productID = productID_p;
		
        else
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product ID does not exist';
            
		end if;
        
	end $$

delimiter ;


drop procedure if exists totalRevenue;
delimiter $$
create procedure totalRevenue(email_p varchar(100))
	begin
		declare sellerID_var int;
        set sellerID_var = (select sellerID from seller where email = email_p limit 1);
        set @id = sellerID_var;
        -- sum of total for a sellerID
		set @sql1 = ' select COALESCE(sum(total),0)  from payment join orders using(orderID)
			join product using(productID)
            where sellerID = ?';
		prepare stmt from @sql1;
        execute stmt using @id;
	end $$



drop procedure if exists totalProfit; 
delimiter $$
 create procedure totalProfit(email_p varchar(100))
	begin
		declare sellerID_var int;
        set sellerID_var = (select sellerID from seller where email = email_p limit 1);
        -- sum of total for a sellerID
		(select COALESCE(sum(msrp - unitPrice), 0) from product join orders using(productID) where sellerID = sellerID_var);
	end $$
delimiter ;


drop function if exists maximumProductSold;
delimiter $$
create function maximumProductSold(email_p varchar(100))
		returns varchar(255)
        deterministic reads sql data
	begin
		declare result varchar(255);
        declare sellerID_var int;
        
		set sellerID_var = (select sellerID from seller where email = email_p limit 1); 
		set result = (select name from product join orders using(productID) where sellerID = sellerID_var
							group by productID order by count(productID) desc  limit 1);
      return result;
    end $$
delimiter ;


drop procedure if exists getShipper; 
delimiter $$
create procedure getShipper(email_p varchar(100))
	begin
		select * from shipper where email=email_p;
	end $$
delimiter ;


drop procedure if exists getUnpickedOrders; 
delimiter $$
create procedure getUnpickedOrders()
	begin
		select orders.orderID, orders.timestamp, orderTracking.status, product.productID, orders.quantity from orders join orderTracking on orders.orderID = orderTracking.orderID join product on orders.productID = product.productID  where shipperID IS NULL and orderTracking.status='ORDERED';
	end $$
delimiter ;



drop procedure if exists updateShipperID; 
delimiter $$
create procedure updateShipperID(orderID_p int, email_p varchar(100))
	begin
		update orders set shipperID = (select shipperID from shipper where email=email_p) where orderID = orderID_p;
	end $$
delimiter ;



drop procedure if exists getPickedOrders; 
delimiter $$
create procedure getPickedOrders(email_p varchar(100))
	begin
		declare shipperID_var int;
		set shipperID_var = (select shipperID from shipper where email = email_p limit 1); 
	SELECT 
    orders.orderID,
    orders.timestamp,
    orderTracking.status,
    product.productID,
    orders.quantity
FROM
    orders
        JOIN
    orderTracking ON orders.orderID = orderTracking.orderID
        JOIN
    product ON orders.productID = product.productID
WHERE
    shipperID = shipperID_var
	order by orderTracking.status desc, orders.orderID asc  ;
	end $$
delimiter ;


drop procedure if exists updateOrderStatus; 
delimiter $$
create procedure updateOrderStatus(orderID_p INT, status enum('IN-TRANSIT', 'DELIVERED'))
	begin
		insert into orderTracking values(orderID_p, status, CURRENT_DATE());
    end $$
delimiter ;


drop procedure if exists monthlyRevenue;
delimiter $$
create procedure monthlyRevenue(email_p varchar(100))
	begin
		declare sellerID_var int;
        set sellerID_var = (select sellerID from seller where email= email_p);
		select substring(payment.timestamp,1,7) months, sum(total) from payment join  orders using(orderID)
        join product using(productID) where sellerID = sellerID_var group by months order by months ;
    end $$
delimiter ;


drop procedure if exists deleteReview;
delimiter $$
create procedure deleteReview(reviewID_p int)
begin
	set @id = reviewID_p;
	set @sql1 = 'delete from review where reviewID = ?';
	-- delete from review where reviewID = reviewID_p;
    prepare stmt from @sql1;
    execute stmt using @id;
    deallocate prepare stmt;
end $$
delimiter ;



drop trigger if exists error_if_order_quantity_less_than_zero;
delimiter $$
create trigger error_if_order_quantity_less_than_zero
	before insert on orders 
    for each row
    begin		
    -- check if the prodcut.units = 0. 
		if (NEW.quantity)<=0  then
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order Quantity cant be less than 1';
		end if;
    end $$
delimiter ;


drop trigger if exists delist_product_for_zero_units;
delimiter $$
create trigger delist_product_for_zero_units
	after insert on orders 
    for each row
    begin
		declare status_var enum('ACTIVE','INACTIVE');
        declare units_var int;
        declare productID_var int;
        set productID_var = NEW.productID;
        set units_var = (select units from product where product.productID = productID_var);
        set status_var = 'INACTIVE';
        
        
    --  if the prodcut.units = 0 and product.status =  active then, make that tuple inactive. 
		if (select units from product where productID = productID_var)<=0 
         and  (select status from product where productID = productID_var) in ('ACTIVE') then			
 			update product set status = 2 where productID = NEW.productID;
		end if;
		
    end $$
delimiter ;