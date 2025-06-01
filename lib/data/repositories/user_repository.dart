import '../models/user.dart';
import '../datasources/local/user_dao.dart';

class UserRepository {
  final UserDao _userDao;

  UserRepository(this._userDao);

  Future<String> createUser({
    required String name,
    required String email,
  }) async {
    return await _userDao.createUser(name: name, email: email);
  }

  Future<User?> getUserById(String id) async {
    return await _userDao.getUserById(id);
  }

  Future<User?> getUserByEmail(String email) async {
    return await _userDao.getUserByEmail(email);
  }

  Future<List<User>> getAllUsers() async {
    return await _userDao.getAllUsers();
  }

  Future<void> updateUser(User user) async {
    await _userDao.updateUser(user);
  }

  Future<void> updateLastLogin(String userId) async {
    await _userDao.updateLastLogin(userId);
  }

  Future<void> deleteUser(String id) async {
    await _userDao.deleteUser(id);
  }

  Future<User?> loginUser(String email) async {
    final user = await getUserByEmail(email);
    if (user != null) {
      await updateLastLogin(user.id);
      return await getUserById(user.id); // Get updated user with new lastLoginAt
    }
    return null;
  }
}
