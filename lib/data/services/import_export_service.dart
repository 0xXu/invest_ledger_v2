import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/shared_investment.dart';
import '../models/investment_goal.dart';
import '../models/import_result.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/shared_investment_repository.dart';
import '../repositories/investment_goal_repository.dart';

class ImportExportService {
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;
  final SharedInvestmentRepository _sharedInvestmentRepository;
  final InvestmentGoalRepository _investmentGoalRepository;

  ImportExportService({
    required TransactionRepository transactionRepository,
    required UserRepository userRepository,
    required SharedInvestmentRepository sharedInvestmentRepository,
    required InvestmentGoalRepository investmentGoalRepository,
  })  : _transactionRepository = transactionRepository,
        _userRepository = userRepository,
        _sharedInvestmentRepository = sharedInvestmentRepository,
        _investmentGoalRepository = investmentGoalRepository;

  /// 导出交易记录为CSV格式
  Future<String?> exportTransactionsToCSV(String userId) async {
    try {
      final transactions = await _transactionRepository.getTransactionsByUserId(userId);

      if (transactions.isEmpty) {
        throw Exception('没有交易记录可导出');
      }

      // CSV标题行
      final List<List<String>> csvData = [
        [
          '日期',
          '股票代码',
          '股票名称',
          '交易类型',
          '数量',
          '价格',
          '总金额',
          '手续费',
          '备注',
        ],
      ];

      // 添加数据行
      for (final transaction in transactions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.stockCode,
          transaction.stockName,
          'buy', // 默认为买入，因为当前模型没有交易类型字段
          transaction.amount.toString(),
          transaction.unitPrice.toString(),
          (transaction.amount * transaction.unitPrice).toString(),
          '0', // 默认手续费为0，因为当前模型没有手续费字段
          transaction.notes ?? '',
        ]);
      }

      // 转换为CSV字符串
      final csvString = const ListToCsvConverter().convert(csvData);

      // 选择保存位置
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存交易记录',
        fileName: 'transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvString, encoding: utf8);
        return outputFile;
      }

      return null;
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  /// 从CSV文件导入交易记录
  Future<int> importTransactionsFromCSV(String userId) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: '选择交易记录CSV文件',
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('未选择文件');
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString(encoding: utf8);

      // 解析CSV
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty) {
        throw Exception('CSV文件为空');
      }

      // 跳过标题行
      final dataRows = csvData.skip(1).toList();
      int importedCount = 0;

      for (final row in dataRows) {
        if (row.length < 8) continue; // 跳过不完整的行

        try {
          final transaction = Transaction(
            id: null, // 将在保存时生成
            userId: userId,
            stockCode: row[1].toString(),
            stockName: row[2].toString(),
            amount: Decimal.parse(row[4].toString()),
            unitPrice: Decimal.parse(row[5].toString()),
            profitLoss: Decimal.zero, // 默认盈亏为0
            date: DateFormat('yyyy-MM-dd').parse(row[0].toString()),
            createdAt: DateTime.now(),
            notes: row.length > 8 ? row[8].toString() : null,
          );

          await _transactionRepository.addTransaction(transaction);
          importedCount++;
        } catch (e) {
          // 跳过无法解析的行
          continue;
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  /// 从TXT文件导入交易记录
  /// TXT文件格式支持多种常见格式：
  /// 格式1（标准格式）: 日期 股票代码 股票名称 数量 单价 备注
  /// 格式2（盈亏格式）: 股票名称：盈XXX元，日期
  /// 格式3（制表符分隔）: 日期\t股票代码\t股票名称\t数量\t单价\t备注
  /// 格式4（逗号分隔）: 日期,股票代码,股票名称,数量,单价,备注
  Future<TxtImportResult> importTransactionsFromTXT(String userId) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: '选择交易记录TXT文件',
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('未选择文件');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      if (content.trim().isEmpty) {
        throw Exception('TXT文件为空');
      }

      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        throw Exception('TXT文件没有有效数据');
      }

      // 检测数据格式
      final detectedFormat = _detectDataFormat(lines);

      // 获取现有交易记录用于去重
      final existingTransactions = await _transactionRepository.getTransactionsByUserId(userId);
      final existingKeys = existingTransactions.map((t) => TransactionKey(
        userId: t.userId,
        date: t.date,
        stockCode: t.stockCode,
        stockName: t.stockName,
      )).toSet();

      int successCount = 0;
      int duplicateCount = 0;
      int errorCount = 0;
      final List<ImportError> errors = [];

      for (int i = 0; i < lines.length; i++) {
        final lineNumber = i + 1;
        final trimmedLine = lines[i].trim();

        // 跳过空行和注释行
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#') || trimmedLine.startsWith('//')) {
          continue;
        }

        try {
          Transaction? transaction;

          switch (detectedFormat) {
            case TxtDataFormat.profitLoss:
              transaction = _parseProfitLossFormat(trimmedLine, userId);
              break;
            case TxtDataFormat.standard:
            case TxtDataFormat.tabSeparated:
            case TxtDataFormat.commaSeparated:
              transaction = _parseStandardFormat(trimmedLine, userId, detectedFormat);
              break;
            default:
              throw Exception('不支持的数据格式');
          }

          // 检查重复
          final transactionKey = TransactionKey(
            userId: transaction.userId,
            date: transaction.date,
            stockCode: transaction.stockCode,
            stockName: transaction.stockName,
          );

          if (existingKeys.contains(transactionKey)) {
            duplicateCount++;
            errors.add(ImportError(
              lineNumber: lineNumber,
              lineContent: trimmedLine,
              errorType: '重复数据',
              errorMessage: '该交易记录已存在',
            ));
          } else {
            await _transactionRepository.addTransaction(transaction);
            existingKeys.add(transactionKey); // 添加到已存在集合中，避免同一批次内重复
            successCount++;
          }
                } catch (e) {
          errorCount++;
          errors.add(ImportError(
            lineNumber: lineNumber,
            lineContent: trimmedLine,
            errorType: '解析错误',
            errorMessage: e.toString(),
          ));
        }
      }

      return TxtImportResult(
        totalLines: lines.length,
        successCount: successCount,
        duplicateCount: duplicateCount,
        errorCount: errorCount,
        errors: errors,
        detectedFormat: detectedFormat.description,
      );
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  /// 检测数据格式类型
  TxtDataFormat _detectDataFormat(List<String> lines) {
    if (lines.isEmpty) return TxtDataFormat.unknown;

    // 检查前几行来确定格式
    final sampleLines = lines.take(5).toList();

    for (final line in sampleLines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#') || trimmedLine.startsWith('//')) {
        continue;
      }

      // 检测盈亏格式: 股票名称：盈XXX元，日期
      if (RegExp(r'^.+：[盈亏]\d+元，\d{4}年\d{1,2}月\d{1,2}日$').hasMatch(trimmedLine)) {
        return TxtDataFormat.profitLoss;
      }

      // 检测制表符分隔
      if (trimmedLine.contains('\t')) {
        final parts = trimmedLine.split('\t');
        if (parts.length >= 5) {
          return TxtDataFormat.tabSeparated;
        }
      }

      // 检测逗号分隔
      if (trimmedLine.contains(',')) {
        final parts = trimmedLine.split(',');
        if (parts.length >= 5) {
          return TxtDataFormat.commaSeparated;
        }
      }

      // 检测空格分隔的标准格式
      final parts = trimmedLine.split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        return TxtDataFormat.standard;
      }
    }

    return TxtDataFormat.unknown;
  }

  /// 解析盈亏格式: 股票名称：盈XXX元，日期
  Transaction _parseProfitLossFormat(String line, String userId) {
    final regex = RegExp(r'^(.+)：([盈亏])(\d+)元，(\d{4}年\d{1,2}月\d{1,2}日)$');
    final match = regex.firstMatch(line);

    if (match == null) {
      throw FormatException('无法解析盈亏格式: $line');
    }

    final stockName = match.group(1)!.trim();
    final profitLossType = match.group(2)!;
    final amount = int.parse(match.group(3)!);
    final dateStr = match.group(4)!;

    // 解析中文日期
    final dateRegex = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
    final dateMatch = dateRegex.firstMatch(dateStr);
    if (dateMatch == null) {
      throw FormatException('无法解析日期: $dateStr');
    }

    final year = int.parse(dateMatch.group(1)!);
    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);
    final date = DateTime(year, month, day);

    // 计算盈亏金额（盈为正，亏为负）
    final profitLoss = profitLossType == '盈' ? Decimal.fromInt(amount) : Decimal.fromInt(-amount);

    // 生成股票代码（如果没有的话，使用股票名称的拼音首字母或简化版本）
    final stockCode = _generateStockCode(stockName);

    return Transaction(
      id: null,
      userId: userId,
      date: date,
      stockCode: stockCode,
      stockName: stockName,
      amount: Decimal.one, // 默认数量为1
      unitPrice: profitLoss.abs(), // 单价设为盈亏金额的绝对值
      profitLoss: profitLoss,
      createdAt: DateTime.now(),
      notes: '从盈亏记录导入',
    );
  }

  /// 解析标准格式
  Transaction _parseStandardFormat(String line, String userId, TxtDataFormat format) {
    List<String> parts;

    switch (format) {
      case TxtDataFormat.tabSeparated:
        parts = line.split('\t');
        break;
      case TxtDataFormat.commaSeparated:
        parts = line.split(',');
        break;
      case TxtDataFormat.standard:
      default:
        parts = line.split(RegExp(r'\s+'));
        break;
    }

    if (parts.length < 5) {
      throw FormatException('数据字段不足，至少需要5个字段: $line');
    }

    return Transaction(
      id: null,
      userId: userId,
      date: _parseDate(parts[0].trim()),
      stockCode: parts[1].trim(),
      stockName: parts[2].trim(),
      amount: Decimal.parse(parts[3].trim()),
      unitPrice: Decimal.parse(parts[4].trim()),
      profitLoss: Decimal.zero,
      createdAt: DateTime.now(),
      notes: parts.length > 5 ? parts[5].trim() : null,
    );
  }

  /// 生成股票代码
  String _generateStockCode(String stockName) {
    // 简单的股票代码生成逻辑
    // 实际应用中可能需要更复杂的逻辑或查询数据库
    if (stockName.length <= 6) {
      return stockName.toUpperCase();
    }

    // 取前3个字符和后3个字符
    return '${stockName.substring(0, 3)}${stockName.substring(stockName.length - 3)}'.toUpperCase();
  }

  /// 解析日期字符串，支持多种格式
  DateTime _parseDate(String dateStr) {
    final cleanDateStr = dateStr.trim();

    // 支持的日期格式
    final dateFormats = [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'yyyyMMdd',
    ];

    for (final format in dateFormats) {
      try {
        return DateFormat(format).parse(cleanDateStr);
      } catch (e) {
        continue;
      }
    }

    // 如果所有格式都失败，尝试使用DateTime.parse
    try {
      return DateTime.parse(cleanDateStr);
    } catch (e) {
      throw FormatException('无法解析日期格式: $cleanDateStr');
    }
  }

  /// 导出完整数据备份（JSON格式）
  Future<String?> exportFullBackup(String userId) async {
    try {
      // 获取所有数据
      final user = await _userRepository.getUserById(userId);
      final transactions = await _transactionRepository.getTransactionsByUserId(userId);
      final sharedInvestments = await _sharedInvestmentRepository.getSharedInvestmentsByUserId(userId);
      final investmentGoals = await _investmentGoalRepository.getGoalsByUserId(userId);

      // 构建备份数据
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'user': user?.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'sharedInvestments': sharedInvestments.map((s) => s.toJson()).toList(),
        'investmentGoals': investmentGoals.map((g) => g.toJson()).toList(),
      };

      // 转换为JSON字符串
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // 选择保存位置
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存数据备份',
        fileName: 'invest_ledger_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString, encoding: utf8);
        return outputFile;
      }

      return null;
    } catch (e) {
      throw Exception('备份失败: $e');
    }
  }

  /// 从备份文件恢复数据
  Future<Map<String, int>> importFullBackup() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('未选择文件');
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString(encoding: utf8);

      // 解析JSON
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      int transactionsImported = 0;
      int sharedInvestmentsImported = 0;
      int investmentGoalsImported = 0;

      // 导入交易记录
      if (backupData['transactions'] != null) {
        final List<dynamic> transactionsData = backupData['transactions'];
        for (final transactionData in transactionsData) {
          try {
            final transaction = Transaction.fromJson(transactionData);
            await _transactionRepository.addTransaction(transaction);
            transactionsImported++;
          } catch (e) {
            // 跳过无法导入的记录
            continue;
          }
        }
      }

      // 导入共享投资
      if (backupData['sharedInvestments'] != null) {
        final List<dynamic> sharedInvestmentsData = backupData['sharedInvestments'];
        for (final sharedInvestmentData in sharedInvestmentsData) {
          try {
            final sharedInvestment = SharedInvestment.fromJson(sharedInvestmentData);
            await _sharedInvestmentRepository.createSharedInvestment(sharedInvestment);
            sharedInvestmentsImported++;
          } catch (e) {
            // 跳过无法导入的记录
            continue;
          }
        }
      }

      // 导入投资目标
      if (backupData['investmentGoals'] != null) {
        final List<dynamic> investmentGoalsData = backupData['investmentGoals'];
        for (final investmentGoalData in investmentGoalsData) {
          try {
            final investmentGoal = InvestmentGoal.fromJson(investmentGoalData);
            await _investmentGoalRepository.addGoal(investmentGoal);
            investmentGoalsImported++;
          } catch (e) {
            // 跳过无法导入的记录
            continue;
          }
        }
      }

      return {
        'transactions': transactionsImported,
        'sharedInvestments': sharedInvestmentsImported,
        'investmentGoals': investmentGoalsImported,
      };
    } catch (e) {
      throw Exception('恢复失败: $e');
    }
  }

  /// 获取应用数据目录
  Future<String> getAppDataDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 自动备份数据
  Future<String> autoBackup(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/invest_ledger_backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 获取所有数据
      final user = await _userRepository.getUserById(userId);
      final transactions = await _transactionRepository.getTransactionsByUserId(userId);
      final sharedInvestments = await _sharedInvestmentRepository.getSharedInvestmentsByUserId(userId);
      final investmentGoals = await _investmentGoalRepository.getGoalsByUserId(userId);

      // 构建备份数据
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'user': user?.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'sharedInvestments': sharedInvestments.map((s) => s.toJson()).toList(),
        'investmentGoals': investmentGoals.map((g) => g.toJson()).toList(),
      };

      // 保存备份文件
      final backupFile = File('${backupDir.path}/auto_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json');
      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
        encoding: utf8,
      );

      // 清理旧的备份文件（保留最近10个）
      await _cleanOldBackups(backupDir);

      return backupFile.path;
    } catch (e) {
      throw Exception('自动备份失败: $e');
    }
  }

  /// 清理旧的备份文件
  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().where((entity) => entity is File).cast<File>().toList();

      // 按修改时间排序
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除超过10个的旧文件
      if (files.length > 10) {
        for (int i = 10; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      // 忽略清理错误
    }
  }
}
