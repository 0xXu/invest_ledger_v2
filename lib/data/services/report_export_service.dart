import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction.dart';

class ReportExportService {
  static const String _defaultFileName = 'investment_report';

  /// 导出投资分析报告为PDF
  static Future<String?> exportAnalysisReportToPDF({
    required List<Transaction> transactions,
    required Map<String, dynamic> stats,
    String? customFileName,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
      
      // 创建PDF内容
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // 标题
              pw.Header(
                level: 0,
                child: pw.Text(
                  '投资分析报告',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // 报告信息
              pw.Text(
                '生成时间: ${dateFormatter.format(now)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                '数据范围: ${transactions.isNotEmpty ? DateFormat('yyyy-MM-dd').format(transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b)) : '无'} 至 ${transactions.isNotEmpty ? DateFormat('yyyy-MM-dd').format(transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b)) : '无'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 30),
              
              // 投资概览
              pw.Header(
                level: 1,
                child: pw.Text('投资概览'),
              ),
              pw.SizedBox(height: 10),
              
              _buildStatsTable(stats),
              pw.SizedBox(height: 30),
              
              // 交易记录
              pw.Header(
                level: 1,
                child: pw.Text('交易记录'),
              ),
              pw.SizedBox(height: 10),
              
              _buildTransactionTable(transactions),
            ];
          },
        ),
      );

      // 保存文件
      final fileName = customFileName ?? '${_defaultFileName}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
      final filePath = await _saveFile(
        await pdf.save(),
        fileName,
        'pdf',
      );

      return filePath;
    } catch (e) {
      throw Exception('PDF导出失败: $e');
    }
  }

  /// 导出投资分析报告为CSV
  static Future<String?> exportAnalysisReportToCSV({
    required List<Transaction> transactions,
    required Map<String, dynamic> stats,
    String? customFileName,
  }) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // 添加标题
      csvData.add(['投资分析报告']);
      csvData.add(['生成时间', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())]);
      csvData.add([]);
      
      // 添加统计信息
      csvData.add(['投资概览']);
      csvData.add(['指标', '数值']);
      csvData.add(['总盈利', '¥${((stats['totalProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}']);
      csvData.add(['总亏损', '¥${((stats['totalLoss'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}']);
      csvData.add(['净盈亏', '¥${((stats['netProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}']);
      csvData.add(['交易次数', '${stats['tradeCount'] ?? 0}']);
      csvData.add(['胜率', '${((stats['winRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%']);
      csvData.add(['盈亏比', (((stats['profitLossRatio'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2))]);
      csvData.add(['ROI', '${((stats['roi'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}%']);
      csvData.add([]);
      
      // 添加交易记录
      csvData.add(['交易记录']);
      csvData.add(['日期', '股票代码', '股票名称', '股数', '单价', '盈亏', '标签', '备注']);
      
      for (final transaction in transactions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.stockCode,
          transaction.stockName,
          transaction.amount.toString(),
          '¥${transaction.unitPrice.toStringAsFixed(2)}',
          '¥${transaction.profitLoss.toStringAsFixed(2)}',
          transaction.tags.join(', '),
          transaction.notes ?? '',
        ]);
      }

      // 转换为CSV字符串
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // 保存文件
      final fileName = customFileName ?? '${_defaultFileName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = await _saveFile(
        csvString.codeUnits,
        fileName,
        'csv',
      );

      return filePath;
    } catch (e) {
      throw Exception('CSV导出失败: $e');
    }
  }

  /// 构建统计信息表格
  static pw.Widget _buildStatsTable(Map<String, dynamic> stats) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('指标', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('数值', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        _buildStatsRow('总盈利', '¥${((stats['totalProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
        _buildStatsRow('总亏损', '¥${((stats['totalLoss'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
        _buildStatsRow('净盈亏', '¥${((stats['netProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
        _buildStatsRow('交易次数', '${stats['tradeCount'] ?? 0}'),
        _buildStatsRow('胜率', '${((stats['winRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%'),
        _buildStatsRow('盈亏比', ((stats['profitLossRatio'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)),
        _buildStatsRow('ROI', '${((stats['roi'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}%'),
      ],
    );
  }

  /// 构建统计信息行
  static pw.TableRow _buildStatsRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  /// 构建交易记录表格
  static pw.Widget _buildTransactionTable(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return pw.Text('暂无交易记录');
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(60),
      },
      children: [
        // 表头
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('日期'),
            _buildTableHeader('代码'),
            _buildTableHeader('名称'),
            _buildTableHeader('股数'),
            _buildTableHeader('单价'),
            _buildTableHeader('盈亏'),
          ],
        ),
        // 数据行
        ...transactions.take(50).map((transaction) => pw.TableRow(
          children: [
            _buildTableCell(DateFormat('MM-dd').format(transaction.date)),
            _buildTableCell(transaction.stockCode),
            _buildTableCell(transaction.stockName),
            _buildTableCell(transaction.amount.toString()),
            _buildTableCell('¥${transaction.unitPrice.toStringAsFixed(2)}'),
            _buildTableCell('¥${transaction.profitLoss.toStringAsFixed(2)}'),
          ],
        )),
      ],
    );
  }

  /// 构建表格标题
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  /// 构建表格单元格
  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  /// 保存文件
  static Future<String?> _saveFile(List<int> bytes, String fileName, String extension) async {
    try {
      // 获取用户选择的保存路径
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存报告',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        return result;
      }
      return null;
    } catch (e) {
      // 如果文件选择器失败，尝试保存到默认位置
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (e) {
        throw Exception('文件保存失败: $e');
      }
    }
  }
}
