import 'package:hj_lib/api.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'user.g.dart';

@JsonSerializable()
@Entity()
class User {
  int id;

  @Index() // or alternatively use @Unique()
  String uid;

  String firstName;
  String lastName;

  User(
      {this.id = 0,
      this.uid = "",
      required this.firstName,
      required this.lastName});
  User.fromUid(
      {this.id = 0,
      required this.uid,
      this.firstName = "",
      this.lastName = ""});
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  Future<User?> About() {
    return Hj.instance.AboutUser(userId: uid);
  }
}
