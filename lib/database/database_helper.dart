import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('CreditClear.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        personName $textType,
        amount $realType,
        type $textType,
        category $textType,
        description TEXT,
        date $textType,
        dueDate TEXT,
        status $textType,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id $idType,
        transactionId $intType,
        amount $realType,
        date $textType,
        note TEXT,
        createdAt $textType,
        FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<TransactionModel?> getTransaction(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertPayment(PaymentModel payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<PaymentModel>> getPaymentsByTransaction(int transactionId) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
      orderBy: 'date DESC',
    );
    return result.map((json) => PaymentModel.fromMap(json)).toList();
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      orderBy: 'date DESC',
    );
    return result.map((json) => PaymentModel.fromMap(json)).toList();
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getStatistics() async {
    final db = await instance.database;
    
    final lentResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ?',
      ['lent'],
    );
    
    final borrowedResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ?',
      ['borrowed'],
    );

    final paidResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments',
    );

    return {
      'totalLent': (lentResult.first['total'] as num).toDouble(),
      'totalBorrowed': (borrowedResult.first['total'] as num).toDouble(),
      'totalPaid': (paidResult.first['total'] as num).toDouble(),
    };
  }

  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('payments');
    await db.delete('transactions');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}