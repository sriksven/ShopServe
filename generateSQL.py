from faker import Faker
from random import randint
faker = Faker(locale="en_US")

for i in range(100):
    firstName = faker.first_name()
    lastName = faker.last_name()
    email = faker.email()
    password = faker.password()
    phone = randint(1000000000, 9999999999)
    street = faker.street_address()
    city = faker.city()
    state = faker.state_abbr()
    zipcode = faker.zipcode()
    #print(firstName, lastName,  email, password, phone, street, city, state)
    print("insert into users(firstName, lastName, email, password, phoneNo, street, city, state, zipcode) "
    +"values(\""+firstName+"\", \""+lastName+"\", \""+email+"\", \""+password+"\", \""+str(phone)+"\", \""+street+"\", \""+city+"\", \""+state+"\", \""+zipcode+"\");")
