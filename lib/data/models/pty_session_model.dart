class PtySessionModel {
  const PtySessionModel({
    required this.id,
    required this.title,
    required this.command,
    required this.args,
    required this.cwd,
    required this.status,
    required this.pid,
  });

  factory PtySessionModel.fromJson(Map<String, dynamic> json) {
    return PtySessionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      command: json['command'] as String? ?? '',
      args: ((json['args'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      cwd: json['cwd'] as String? ?? '',
      status: json['status'] as String? ?? '',
      pid: json['pid'] as int? ?? 0,
    );
  }

  final String id;
  final String title;
  final String command;
  final List<String> args;
  final String cwd;
  final String status;
  final int pid;
}
