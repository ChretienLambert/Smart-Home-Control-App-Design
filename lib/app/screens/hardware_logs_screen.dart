import 'package:flutter/material.dart';
import '../../core/services/logger_service.dart';

class HardwareLogsScreen extends StatefulWidget {
  const HardwareLogsScreen({super.key});

  @override
  State<HardwareLogsScreen> createState() => _HardwareLogsScreenState();
}

class _HardwareLogsScreenState extends State<HardwareLogsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoscroll = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Debug Logs'),
        actions: [
          IconButton(
            icon: Icon(_autoscroll ? Icons.vertical_align_bottom : Icons.vertical_align_top),
            onPressed: () => setState(() => _autoscroll = !_autoscroll),
            tooltip: 'Toggle Autoscroll',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => LoggerService().clearLogs(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: StreamBuilder<List<LogEntry>>(
        stream: LoggerService().logsStream,
        initialData: LoggerService().logs,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          
          if (_autoscroll && _scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            });
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _LogEntryWidget(log: log);
            },
          );
        },
      ),
    );
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry log;

  const _LogEntryWidget({required this.log});

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return Colors.grey;
      case LogLevel.info: return Colors.blue;
      case LogLevel.warning: return Colors.orange;
      case LogLevel.error:
      case LogLevel.critical: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = log.timestamp.toIso8601String().substring(11, 19);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[$timeStr] ',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getLevelColor(log.level).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace', 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(log.level),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.message,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
          ),
          if (log.context != null && log.context!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 60, top: 4),
              child: Text(
                log.context.toString(),
                style: TextStyle(
                  fontFamily: 'monospace', 
                  fontSize: 11, 
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Divider(height: 8, thickness: 0.5),
        ],
      ),
    );
  }
}
