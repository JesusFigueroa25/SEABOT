import 'user.dart';

class Student {
  final int? id;
  final int? userId;
  final String? alias;
  final String? safeContact;
  final User? user;

  Student({this.id, this.userId, this.alias, this.safeContact, this.user});

  //toma un JSON y conviértelo en un objeto Student.
  //GET - Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      alias: json['alias'],
      safeContact: json['safe_contact'],
    );
  }

  factory Student.fromJsonCreateUserStudent(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      alias: json['alias'],
      safeContact: json['safe_contact'],
    );
  }
  factory Student.fromJsonStudent(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      alias: json['alias'],
      safeContact: json['safe_contact'],
    );
  }

  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {'id': id, 'alias': alias, 'safe_contact': safeContact};
  }
}
