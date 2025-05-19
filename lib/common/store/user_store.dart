import 'package:mobx/mobx.dart';

import '../../client/model/user_model.dart';
part 'user_store.g.dart';



class UserStore = _UserStore with _$UserStore;

abstract class _UserStore with Store {
  @observable
  UserModel? user;

  @action
  Future<void> updateUserData(UserModel newUserData) async {
    user = newUserData;
  }
}