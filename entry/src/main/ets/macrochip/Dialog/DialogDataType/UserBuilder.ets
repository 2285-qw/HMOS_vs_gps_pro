class UserBuilder {
  private name: string = "";
  private age: number = 0;
  private email: string = "";
  private phone: string = "";

  setName(name: string): UserBuilder {
    this.name = name;
    return this;
  }
  setAge(age: number): UserBuilder {
    this.age = age;
    return this;
  }
  setEmail(email: string): UserBuilder {
    this.email = email;
    return this;
  }
  setPhone(phone: string): UserBuilder {
    this.phone = phone;
    return this;
  }
  build(): User {
    return new User(this.name, this.age, this.email, this.phone);
  }
}

class User {
  name: string;
  age: number;
  email: string;
  phone: string;

  constructor(name: string, age: number, email: string, phone: string) {
    this.name = name;
    this.age = age;
    this.email = email;
    this.phone = phone;
  }
}
// 使用示例
const user = new UserBuilder()
  .setName("张三")
  .setAge(25)
  .setEmail("zhangsan@example.com")
  .setPhone("13800138000")
  .build();
