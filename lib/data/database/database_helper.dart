import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

import '../../core/utils/app_logger.dart';

class DatabaseHelper {
  static const String _databaseName = 'invest_ledger.db';
  static const int _databaseVersion = 4;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // 初始化 FFI (用于桌面平台)
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (e) {
      // Web 平台不支持 Platform 检测，使用默认数据库工厂
      AppLogger.warning('Platform detection failed (likely running on web): $e');
    }

    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加投资目标表
      await db.execute('''
        CREATE TABLE investment_goals (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL,
          period TEXT NOT NULL,
          year INTEGER NOT NULL,
          month INTEGER,
          target_amount TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_investment_goals_user_id ON investment_goals(user_id)');
      await db.execute('CREATE INDEX idx_investment_goals_period ON investment_goals(user_id, type, period, year, month)');
    }

    if (oldVersion < 3) {
      // AI建议表功能已移除，跳过该版本更新
    }

    if (oldVersion < 4) {
      // 添加软删除字段到现有表
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (e) {
        AppLogger.warning('transactions表is_deleted字段可能已存在: $e');
      }

      try {
        await db.execute('ALTER TABLE investment_goals ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (e) {
        AppLogger.warning('investment_goals表is_deleted字段可能已存在: $e');
      }
    }
  }

  static Future<void> _createTables(Database db) async {

    // 交易表
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        stock_code TEXT NOT NULL,
        stock_name TEXT NOT NULL,
        amount TEXT NOT NULL,
        unit_price TEXT NOT NULL,
        profit_loss TEXT NOT NULL,
        tags TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 标签表
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, name)
      )
    ''');

    // 投资目标表
    await db.execute('''
      CREATE TABLE investment_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        period TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER,
        target_amount TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_stock_code ON transactions(stock_code)');
    await db.execute('CREATE INDEX idx_investment_goals_user_id ON investment_goals(user_id)');
    await db.execute('CREATE INDEX idx_investment_goals_period ON investment_goals(user_id, type, period, year, month)');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
