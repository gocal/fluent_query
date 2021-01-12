import 'package:fluent_query/fluent_query.dart';

part 'model.g.dart';

@fluentModel
class User {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.birthDate,
  });
}
