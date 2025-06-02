import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'invest_ledger.db';
  static const int _databaseVersion = 3;

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
      print('Platform detection failed (likely running on web): $e');
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
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_investment_goals_user_id ON investment_goals(user_id)');
      await db.execute('CREATE INDEX idx_investment_goals_period ON investment_goals(user_id, type, period, year, month)');
    }

    if (oldVersion < 3) {
      // 添加AI建议表
      await db.execute('''
        CREATE TABLE ai_suggestions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          analysis_data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          executed_at TEXT,
          transaction_id TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          user_notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_ai_suggestions_user_id ON ai_suggestions(user_id)');
      await db.execute('CREATE INDEX idx_ai_suggestions_status ON ai_suggestions(user_id, status)');
      await db.execute('CREATE INDEX idx_ai_suggestions_created_at ON ai_suggestions(created_at)');
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
        shared_investment_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (shared_investment_id) REFERENCES shared_investments (id)
      )
    ''');

    // 共享投资表
    await db.execute('''
      CREATE TABLE shared_investments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        stock_code TEXT NOT NULL,
        stock_name TEXT NOT NULL,
        total_amount TEXT NOT NULL,
        total_shares TEXT NOT NULL,
        initial_price TEXT NOT NULL,
        current_price TEXT,
        sell_amount TEXT,
        created_date TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // 共享投资参与者表
    await db.execute('''
      CREATE TABLE shared_investment_participants (
        id TEXT PRIMARY KEY,
        shared_investment_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        investment_amount TEXT NOT NULL,
        shares TEXT NOT NULL,
        profit_loss TEXT NOT NULL,
        transaction_id TEXT,
        FOREIGN KEY (shared_investment_id) REFERENCES shared_investments (id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE SET NULL
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
        updated_at TEXT
      )
    ''');

    // AI建议表
    await db.execute('''
      CREATE TABLE ai_suggestions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        analysis_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        executed_at TEXT,
        transaction_id TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        user_notes TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE SET NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_stock_code ON transactions(stock_code)');
    await db.execute('CREATE INDEX idx_investment_goals_user_id ON investment_goals(user_id)');
    await db.execute('CREATE INDEX idx_investment_goals_period ON investment_goals(user_id, type, period, year, month)');
    await db.execute('CREATE INDEX idx_ai_suggestions_user_id ON ai_suggestions(user_id)');
    await db.execute('CREATE INDEX idx_ai_suggestions_status ON ai_suggestions(user_id, status)');
    await db.execute('CREATE INDEX idx_ai_suggestions_created_at ON ai_suggestions(created_at)');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
